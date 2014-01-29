classdef ReluHiddenLayer < StandardLayer & HiddenLayer
   
   properties
      %isLocallyLinear = true
   end
   
   methods
      function obj = ReluHiddenLayer(inputSize, outputSize, varargin)
         obj = obj@StandardLayer(inputSize, outputSize, varargin{:});
      end
      
      function init_params(obj)
         if isempty(obj.initScale)
            obj.initScale = 1/obj.inputSize;
         end
         obj.params{1} = matrix_init(obj.outputSize, obj.inputSize, obj.initType, ...
                                          obj.initScale, obj.gpuState);
         obj.params{2} = obj.initScale*obj.gpuState.ones(obj.outputSize, 1);
      end
      
      function y = feed_forward(obj, x, ~)
         z = obj.compute_z(x);
         y = max(0, z);
      end
      
      function [grad, dLdx] = backprop(obj, x, y, dLdy)
         dLdz = dLdy.*(y > 0);
         [grad, dLdx] = obj.grad_from_dLdz(x, dLdz);
      end         
   end   
end

