classdef homog
%HOMOG homogenous coordinates class.
%
% HOMOG(Z1,Z2) creates a homogeneous coordinate representing the complex
% number z = Z1/Z2. If Z2 is nonzero, this is a straightforward idea. If Z2
% is zero, then Z1 represents a tangent direction in the complex plane at
% which Inf is to be approached. This is useful for specifying lines, as
% e.g. there are infinitely many lines through any fixed finite point and
% infinity. 
%
% HOMOG(Z1) uses Z2=1. 
%
% Class instances should interoperate quietly with the double data type.

% This file is a part of the CMToolbox.
% It is licensed under the BSD 3-clause license.
% (See LICENSE.)

% Copyright Toby Driscoll, 2014.
% Written by Everett Kropf, 2014,
% adapted to new classdef from Toby Driscoll's code, originally 20??.

properties
  numerator
  denominator
end

methods
  function zeta = homog(z1, z2)
    % Constructor
    if nargin > 0
      if nargin < 2
        if isa(z1, 'homog')
          zeta = z1;
          return
        end
        z2 = [];
      end
      
      if ~isequal(size(z1), size(z2))
        if isempty(z2)
          % Assume 1 for denominator.
          z2 = ones(size(z1));
        elseif numel(z2) == 1
          % Scalar expansion.
          z2 = repmat(z2, size(z1));
        else
          error('Input arguments must be scalar or of the same size.')
        end
      end
      
      % Transform infinities to finite representation. There is no unique
      % choice, so we arbtrarily pick [\pm 1,0] based on the sign.
      idx = isinf(z1);
      z1(idx) = sign(real(z1(idx))) + 1i*sign(imag(z1(idx)));
      z2(idx) = 0;
      
      zeta.numerator = z1;
      zeta.denominator = z2;
    end
  end % ctor
  
  function r = abs(zeta)
    % Return absolute value.
    r = abs(double(zeta));
  end
  
  function theta = angle(zeta)
    % Return phase angle, standardised to [-pi, pi).
    theta = mod(angle(zeta.numerator) - ...
        angle(zeta.denominator) + pi, 2*pi) - pi;
  end
  
  function zeta = cat(dim, varargin)
    % Override double cat().
    numers = cell(nargin - 1, 1);
    denoms = numers;
    for n = 1:nargin - 1
      h = homog(varargin{n});
      numers{n} = h.numerator;
      denoms{n} = h.denominator;
    end
    
    try
      zeta = homog(cat(dim, numers{:}), cat(dim, denoms{:}));
    catch
      error('Argument dimensions are not consistent.')
    end
  end
  
  function zetbar = conj(zeta)
    % Complex conjugate.
    zetbar = homog(conj(zeta.numerator), conj(zeta.denominator));
  end
  
  function eta = ctranspose(zeta)
    % Complex transpose.
    eta = homog(ctranspose(zeta.numerator), ctranspose(zeta.denominator));
  end
  
  function z2 = denom(zeta)
    % Return denominator.
    z2 = zeta.denominator;
  end
  
  function str = char(zeta)
    % Format for text representation.
    z = zeta.numerator./zeta.denominator;
    z(isinf(z)) = complex(Inf,1);  % Get a predictable result for Inf 
   
    if isempty(zeta.numerator)
        str = '[]';
        return
    end
    
    str = num2str(z);
    for row = 1:size(str,1)
        strinf = strfind(str(row,:),'Inf');
        zinf = find(isinf(z(row,:)));
        newstr{row} = str(row,:);
        for i = length(strinf):-1:1  % don't change index values as you go
            k = strinf(i);
            s = angle(zeta.numerator(row,zinf(i)));
            % If it's a complex vector, num2str will call
            newstr{row} = [newstr{row}(1:k+2),...
                sprintf('@(%spi)',num2str(s/pi,'%.2g')),...
                newstr{row}(k+6:end)];
        end
    end
    str = char(newstr{:});
  end
  
  function disp(zeta)
      n = size(zeta.numerator);
      fprintf('%i-by-', n(1:end-1));
      fprintf('%i', n(end));
      fprintf(' array of homogeneous coordinates:\n\n');
      disp(char(zeta));
      fprintf('\n\n');
  end
  
  function z = double(zeta)
    % Convert to double.
    
    % Driscoll's original turned of divide by zero warning. Do we still need
    % this? Newer versions of MATLAB don't give this warning.
    
    z = zeta.numerator./zeta.denominator;
    % Ensure imag(z(isinf(z))) = 0 reliably.
    z(isinf(z)) = Inf;
  end
  
  function e = end(zeta, k, n)
    % Return array end indexes.
    if n == 1
      e = length(zeta.numerator);
    else
      e = size(zeta.numer, k);
    end
  end
  
  function zeta = horzcat(varargin)
    % Provide horizontal contatenation.
    zeta = cat(2, varargin{:});
  end
  
  function y = imag(zeta)
      y = imag(zeta.numerator ./ zeta.denominator);
  end
  
  function z = inv(zeta)
    % Return 1/zeta.
    z = homog(zeta.denominator, zeta.numerator);
  end
    
  function tf = isinf(zeta)
    tf = zeta.denominator == 0 & zeta.numerator ~= 0; 
  end
  
  function n = length(zeta)
    % Length of zeta.
    n = length(zeta.numerator);
  end
  
  function c = minus(a, b)
    % Provide subtraction.
    c = plus(a, -b);
  end
  
  function c = mldivide(a, b)
    % Provide matrix left divide.
    c = mtimes(inv(a), b);
  end
  
  function c = mrdivide(a, b)
    % Provide matrix right divide.
    c = mtimes(a, inv(b));
  end
  
  function c = mtimes(a, b)
    % Provide multiplication.
    if isfloat(a)
      a = homog(a);
    end
    if isfloat(b)
      b = homog(b);
    end
    c = homog(a.numerator*b.numerator, a.denominator*b.denominator);
  end
  
  function s = num2str(zeta)
      s = ['homog( ',num2str(zeta.numerator),...
          ', ',num2str(zeta.denominator), ' )'];
  end
  
  function n = numel(zeta, varargin)
    n = numel(zeta.numerator, varargin{:});
  end
  
  function z1 = numer(zeta)
    % Return numerator.
    z1 = zeta.numerator;
  end
  
  function c = plus(a, b)
    % Provide addition.
    if isfloat(a)
      a = homog(a);
    end
    if isfloat(b)
      b = homog(b);
    end
    c = homog(a.numerator.*b.denominator + a.denominator.*b.numerator, ...
        a.denominator.*b.denominator);
  end
  
  function c = rdivide(a, b)
    if isfloat(a)
      a = homog(a);
    end
    if isfloat(b)
      b = homog(b);
    end
    c = times(a, inv(b));
  end
  
  function x = real(zeta)
      x = real(zeta.numerator ./ zeta.denominator);
  end
  
  function s = sign(zeta)
      s = zeros(size(zeta));
      mask = isinf(zeta);
      s(mask) = sign( zeta.numerator(mask) );
      zdub = double(zeta);
      s(~mask) = sign( zdub(~mask) );
  end
  
  function varargout = size(zeta)
      [varargout{1:nargout}] = size(zeta.numerator);
  end

  function z = subsref(zeta, s)
    % Provide double-like indexing.
    switch s.type
      case '()'
        z = homog(subsref(zeta.numerator, s), subsref(zeta.denominator, s));
      otherwise
        error('This type of indexing is not supported by homog objects.')
    end
  end
  
  function zeta = subsasgn(zeta, s, val)
    % Provide double-like assignment.
    switch s.type
      case '()'
        if length(s.subs) == 1
          zeta = homog(zeta);
          val = homog(val);
          index = s.subs{1};
          zeta.numerator(index) = val.numerator;
          zeta.denominator(index) = val.denominator;
        else
          error('HOMOG objects support linear indexing only.')
        end
      otherwise
        error('Unspported assignment syntax.')
    end
  end
  
  function c = times(a, b)
    if isfloat(a)
      a = homog(a);
    end
    if isfloat(b)
      b = homog(b);
    end
    c = homog(a.numerator.*b.numerator, a.denom.*b.denominator);
  end
  
  function eta = transpose(zeta)
    % Provide basic transpose.
    eta = homog(transpose(zeta.numerator), transpose(zeta.denominator));
  end
  
  function zeta = vertcat(varargin)
    % Provide vertical contatenation.
    zeta = cat(1, varargin{:});
  end
  
  function b = uminus(a)
    % Unitary minus.
    b = homog(-a.numerator, a.denominator);
  end
end

methods (Static)
    function zeta = inf(angle)
        zeta = homog(exp(1i*angle),0);
    end
    
end

end