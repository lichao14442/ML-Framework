classdef LinearZeroBiasLayer < CompositeBaseLayer & matlab.mixin.Copyable & ...
                               ParamsFunctions
   % A standard linear layer but with no bias term.
   
   properties
      inputSize
      outputSize
   end
   
   methods
      function obj = LinearZeroBiasLayer(inputSize, outputSize, varargin)
         obj = obj@ParamsFunctions(varargin{:});
         obj.inputSize = inputSize;
         obj.outputSize = outputSize;
         obj.init_params();
      end
      
      function init_params(obj)
         obj.params{1} = matrix_init(obj.outputSize, obj.inputSize, ...
                                     obj.initType, obj.initScale, obj.gpuState);
      end
      
      function y = feed_forward(obj, x, ~)
         y = obj.params{1}*x;
      end
      
      function [grad, dLdx] = backprop(obj, x, dLdy)
         N = size(x, 2);
         grad{1} = dLdy*x'/N;
         dLdx = obj.params{1}'*dLdy;
      end
      
   end
end

