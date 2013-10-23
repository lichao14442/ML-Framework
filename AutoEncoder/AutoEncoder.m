classdef AutoEncoder < handle
   % Generic denoising AutoEncoder
   
   properties
      encodeLayer % a HiddenLayer object that functions as the encoding layer
      decodeLayer % a OutputLayer object that functions as the decoding layer and loss function
      isTiedWeights % a boolean indicating if the params in encodeLayer and decodeLayer are shared
      gpuState
   end
   
   methods
      function obj = AutoEncoder(varargin)
         p = inputParser;
         p.addParamValue('dropout', []);
         p.addParamValue('isTiedWeights', false);
         p.addParamValue('gpu', []);
         parse(p, varargin{:});

         obj.isTiedWeights = p.Results.isTiedWeights;
         
         if isempty(p.Results.gpu)
            obj.gpuState = GPUState();
         else
            obj.gpuState = GPUState(p.Results.gpu);
         end
      end
      
      function [grad, xRecon] = gradient(obj, xIn, xTarget, ~)
         xIn(isnan(xIn)) = 0;
         xCode = obj.encodeLayer.feed_forward(xIn);
         [decodeGrad, dLdxCode, xRecon] = obj.decodeLayer.backprop(xCode, xTarget);
         encodeGrad = obj.encodeLayer.backprop(xIn, xCode, dLdxCode);
         
         if obj.isTiedWeights
            if ndims(encodeGrad{1}) <= 2
               grad = {encodeGrad{1}+decodeGrad{1}', encodeGrad{2}, decodeGrad{2}};
            else
               grad = {encodeGrad{1}+permute(decodeGrad{1}, [2, 1, 3]), ...
                        encodeGrad{2}, decodeGrad{2}};
            end
         else
            grad = [encodeGrad, decodeGrad];
         end
      end
      
      function loss = compute_loss(obj, xRecon, x)
         loss = obj.decodeLayer.compute_loss(xRecon, x);
      end
      
      function xCode = encode(obj, x)
         x(isnan(x)) = 0;
         xCode = obj.encodeLayer.feed_forward(x);
      end
      
      function xRecon = output(obj, x)
         x(isnan(x)) = 0;
         xCode = obj.encodeLayer.feed_forward(x);
         xRecon = obj.decodeLayer.feed_forward(xCode);
      end
      
      function increment_params(obj, delta_params)
         if obj.isTiedWeights
            obj.encodeLayer.increment_params(delta_params(1:2));
            obj.decodeLayer.increment_params({0, delta_params{3}});
            obj.decodeLayer.params{1} = obj.get_encode_params_transposed();
         else
            splitIdx = length(obj.encodeLayer.params);
            obj.encodeLayer.increment_params(delta_params(1:splitIdx));
            obj.decodeLayer.increment_params(delta_params(splitIdx+1:end));
         end
      end
      
      function gather(obj)
         obj.encodeLayer.gather();
         obj.decodeLayer.gather();
      end
      
      function push_to_GPU(obj)
         obj.encodeLayer.push_to_GPU();
         obj.decodeLayer.push_to_GPU();
      end
      
      function reset(obj)
         obj.encodeLayer.init_params();
         obj.decodeLayer.init_params();
         if obj.isTiedWeights 
            obj.decodeLayer.params{1} = obj.get_encode_params_transposed();
         end
      end
      
      function pTrans = get_encode_params_transposed(obj)
         if ndims(obj.encodeLayer.params{1}) <= 2
            pTrans = obj.encodeLayer.params{1}';
         else
            pTrans = permute(obj.encodeLayer.params{1}, [2, 1, 3]);
         end
      end
      
      function objCopy = copy(obj)
         objCopy = AutoEncoder();
         % Handle properties
         objCopy.encodeLayer = obj.encodeLayer.copy();
         objCopy.decodeLayer = obj.decodeLayer.copy();
         
         % Value properties
         objCopy.isTiedWeights = obj.isTiedWeights;
         objCopy.gpuState = obj.gpuState;
      end
   end
   
end

