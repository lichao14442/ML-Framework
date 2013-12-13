classdef ConvLayer < matlab.mixin.Copyable
   % This defines the interface for ConvLayers
   
   methods (Abstract)
      y = feed_forward(obj, x)
      [grad, dLdx] = backprop(obj, x, dLdy)
      init_params(obj)
      push_to_GPU(obj)
      gather(obj)
      increment_params(obj, delta)
   end
   
end
