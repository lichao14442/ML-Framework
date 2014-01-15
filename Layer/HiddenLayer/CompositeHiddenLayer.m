classdef CompositeHiddenLayer < HiddenLayer
   
   properties
      layers
      nestedGradShape
      flatGradLength
   end
   
   methods
      function init_params(obj)
         for i = 1:length(obj.layers)
            if ismethod(obj.layers{i}, 'init_params')
               obj.layers{i}.init_params();
            end
         end
      end
      
      function y = feed_forward(obj, x, isSave)
         if nargin < 3
            isSave = false;
         end
         
         y = obj.layers{1}.feed_forward(x, isSave);
         for i = 2:length(obj.layers)
            y = obj.layers{i}.feed_forward(y, isSave);
         end
      end
      
      function [grad, dLdx] = backprop(obj, x, ~, dLdy)
         nLayers = length(obj.layers);
         grad = cell(1, nLayers);
         if ismethod(obj.layers{end}, 'increment_params')
            [grad{end}, dLdx] = obj.layers{end}.backprop(dLdy);
         else
            dLdx = obj.layers{end}.backprop(dLdy);
         end
         
         for i = nLayers-1:-1:2
            if ismethod(obj.layers{i}, 'increment_params')
               [grad{i}, dLdx] = obj.layers{i}.backprop(dLdx);
            else
               dLdx = obj.layers{i}.backprop(dLdx);
            end
         end
         
         if ismethod(obj.layers{1}, 'increment_params')
            [grad{1}, dLdx] = obj.layers{1}.backprop(x, dLdx);
         else
            dLdx = obj.layers{1}.backprop(x, dLdx);
         end
         grad = obj.unroll_gradient(grad);
      end
      
      function increment_params(obj, delta)
         delta = obj.roll_gradient(delta);
         for i = 1:length(obj.layers)
            if ismethod(obj.layers{i}, 'increment_params')          
               obj.layers{i}.increment_params(delta{i});
            end            
         end
      end
      
      function gather(obj)
         for i = 1:length(obj.layers)
            if ismethod(obj.layers{i}, 'gather')
               obj.layers{i}.gather();
            end            
         end
      end
      
      function push_to_GPU(obj)
         for i = 1:length(obj.layers)
            if ismethod(obj.layers{i}, 'push_to_GPU')
               obj.layers{i}.push_to_GPU();
            end            
         end
      end
      
      function flatGrad = unroll_gradient(obj, nestedGrad)
         if isempty(obj.nestedGradShape)
            obj.compute_gradient_shapes(nestedGrad);
         end
         
         flatGrad = cell(1, obj.flatGradLength);
         startIdx = 1;
         for i = 1:length(nestedGrad)
            stopIdx = startIdx + obj.nestedGradShape(i) - 1;
            flatGrad(startIdx:stopIdx) = nestedGrad{i};
            startIdx = stopIdx + 1;
         end
      end
      
      function nestedGrad = roll_gradient(obj, flatGrad)
         startIdx = 1;
         nestedLength = length(obj.nestedGradShape);
         nestedGrad = cell(1, nestedLength);
         for i = 1:nestedLength
            stopIdx = startIdx + obj.nestedGradShape(i) - 1;
            nestedGrad{i} = flatGrad(startIdx:stopIdx);
            startIdx = stopIdx + 1;
         end
      end
      
      function compute_gradient_shapes(obj, nestedGrad)
         flatLength = 0;
         nestedShape = zeros(1, length(nestedGrad));
         for i = 1:length(nestedGrad)
            nestedShape(i) = length(nestedGrad{i});
            flatLength = flatLength + nestedShape(i);
         end
         obj.nestedGradShape = nestedShape;
         obj.flatGradLength = flatLength;
      end
      
      function objCopy = copy(obj)
         objCopy = CompositeHiddenLayer();
         nLayers = length(obj.layers);
         objCopy.layers = cell(1, nLayers);
         for i = 1:nLayers
            objCopy.layers{i} = obj.layers{i}.copy();
         end
         objCopy.nestedGradShape = obj.nestedGradShape;
         objCopy.flatGradLength = obj.flatGradLength;
      end
      
   end
end

