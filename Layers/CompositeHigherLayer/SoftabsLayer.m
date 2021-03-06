classdef SoftabsLayer < CompositeHigherLayer & matlab.mixin.Copyable
   % Applies an elementwise soft absolute value to the input.
   
   properties
      dydx
      eps
   end
   
   methods
      function obj = SoftabsLayer(eps)
         if nargin < 1
            eps = 1e-6;
         end
         obj.eps = eps;
      end
      
      function y = feed_forward(obj, x, isSave)
         y = sqrt(x.*x + obj.eps);
         if nargin == 3 && isSave
            obj.dydx = x./y;
         end
      end
      
      function dLdx = backprop(obj, dLdy)
         dLdx = obj.dydx.*dLdy;
         obj.dydx = [];
      end
      
   end
end

