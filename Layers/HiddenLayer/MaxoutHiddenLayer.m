classdef MaxoutHiddenLayer < HiddenLayer & ParamsFunctions & ...
                             WeightDecayPenalty & MaxFanInConstraint ...
                             & matlab.mixin.Copyable
   % A Maxout hidden layer as described in Goodfellow 2013.
   
   properties
      % params = {W, b} where W and b are 3-dimensional arrays
      inputSize
      outputSize
      
      % number of linear units per maxout unit 
      % (size of 3rd dimension of W and b)
      D 
      dydz
   end
   
   methods
      function obj = MaxoutHiddenLayer(inputSize, outputSize, D, varargin)
         obj = obj@ParamsFunctions(varargin{:});
         obj = obj@WeightDecayPenalty(varargin{:});
         obj = obj@MaxFanInConstraint(varargin{:});
         obj.inputSize = inputSize;
         obj.outputSize = outputSize;
         obj.D = D;   
         obj.init_params();
      end
      
      function init_params(obj)
         obj.params{2} = obj.gpuState.zeros(obj.outputSize, 1, obj.D);
         for idx = 1:obj.D
            obj.params{1}(:,:,idx) = matrix_init(obj.outputSize, ...
                  obj.inputSize, obj.initType, obj.initScale, obj.gpuState);
         end
      end
      
      function y = feed_forward(obj, x, isSave)
         z = obj.compute_z(x);
         y = max(z, [], 3);
         
         if nargin == 3 && isSave
            obj.dydz = bsxfun(@eq, z, y);
         end
      end
      
      function [grad, dLdx] = backprop(obj, x, ~, dLdy)
         N = size(x, 2);         

         dLdz = bsxfun(@times, dLdy, obj.dydz); % dimensions are L2 x N x D
         obj.dydz = [];
         
         if obj.gpuState.isGPU
            dLdx = sum(pagefun(@mtimes, ...
                               permute(obj.params{1}, [2, 1, 3]), dLdz), 3);
            grad{1} = pagefun(@mtimes, dLdz, x')/N; % L2 x L1 x D 
         else
            dLdx = zeros(obj.inputSize, N, obj.D);
            grad{1} = zeros(obj.outputSize, obj.inputSize, obj.D);
            for i = 1:obj.D
               dLdx(:,:,i) = obj.params{1}(:,:,i)'*dLdz(:,:,i);
               grad{1}(:,:,i) = dLdz(:,:,i)*x'/N;
            end
            dLdx = sum(dLdx, 3);
         end
         
         grad{2} = mean(dLdz, 2); % L2 x 1 x D
         
         if obj.isWeightDecay
            grad{1} = grad{1} + obj.compute_weight_decay_penalty();
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
      
      function increment_params(obj, delta)
         increment_params@ParamsFunctions(obj, delta);
         if obj.isMaxFanIn
            obj.impose_fanin_constraint();
         end
      end
      
   end
end

