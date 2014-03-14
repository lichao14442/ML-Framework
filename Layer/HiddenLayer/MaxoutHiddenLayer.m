classdef MaxoutHiddenLayer < HiddenLayer & ParamsFunctions & RegularizationFunctions & matlab.mixin.Copyable
   
   properties
      % params = {W, b} where W and b are 3-dimensional arrays
      inputSize
      outputSize
      D % number of linear units per maxout unit (size of 3rd dimension of W and b)
      Dy
      % isLocallyLinear = true
   end
   
   methods
      function obj = MaxoutHiddenLayer(inputSize, outputSize, D, varargin)
         obj = obj@ParamsFunctions(varargin{:});
         obj = obj@RegularizationFunctions(varargin{:});
         obj.inputSize = inputSize;
         obj.outputSize = outputSize;
         obj.D = D;   
         obj.init_params();
      end
      
      function init_params(obj)
         obj.params{2} = obj.gpuState.zeros(obj.outputSize, 1, obj.D);
         for idx = 1:obj.D
            obj.params{1}(:,:,idx) = matrix_init(obj.outputSize, obj.inputSize, obj.initType, ...
                                                      obj.initScale, obj.gpuState);
         end
      end
      
      function y = feed_forward(obj, x, isSave)
         z = obj.compute_z(x);
         y = max(z, [], 3);
         
         if nargin == 3 && isSave
            obj.Dy = bsxfun(@eq, z, y);
         end
      end
      
      function [grad, dLdx] = backprop(obj, x, ~, dLdy)
         N = size(x, 2);         
         dLdz = bsxfun(@times, dLdy, obj.Dy); % dimensions are L2 x N x D
         obj.Dy = [];
         
         if obj.gpuState.isGPU
            dLdx = pagefun(@mtimes, permute(obj.params{1}, [2, 1, 3]), dLdz);
         else
            dLdx = zeros(obj.inputSize, N, obj.D);
            for i = 1:obj.D
               dLdx(:,:,i) = obj.params{1}(:,:,i)'*dLdz;
            end
         end
         dLdx = sum(dLdx, 3);
         
         grad{1} = pagefun(@mtimes, dLdz, x')/N; % L2 x L1 x D
         grad{2} = mean(dLdz, 2); % L2 x 1 x D
         
         if obj.isPenalty
            penalties = obj.compute_penalties();
            grad{1} = grad{1} + penalties{1};
            grad{2} = grad{2} + penalties{2};
         end
      end
      
      function value = compute_z(obj, x)
         % z has dimensions L2 x N x D
         if obj.gpuState.isGPU
            value = pagefun(@mtimes, obj.params{1}, x);
            value = bsxfun(@plus, value, obj.params{2});
         else
            value = zeros(obj.outputSize, size(x, 2), obj.D);
            for i = 1:obj.D
               value(:,:,i) = bsxfun(@plus, obj.params{1}(:,:,i)*x, ...
                                       obj.params{2}(:,:,i));
            end
         end
      end
      
   end
end

