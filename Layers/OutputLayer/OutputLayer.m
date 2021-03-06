classdef OutputLayer < handle
   % Defines the OutputLayer interface.

   methods (Abstract)
      y = feed_forward(obj, x)
      [grad, dLdx, y] = backprop(obj, x, t)
      loss = compute_loss(obj, y, t)
      init_params(obj)
      increment_params(obj, delta)
      push_to_GPU(obj)
      gather(obj)
   end   
end