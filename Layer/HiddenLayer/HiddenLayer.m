classdef HiddenLayer < matlab.mixin.Copyable
   % Defines the HiddenLayer interface 
   
   properties (Abstract)
      isLocallyLinear % need to implement for CAE and ManifoldTangentClassifier
   end

   methods (Abstract)
      [grad, dLdx] = backprop(obj, x, y, ffExtras, dLdy)
      [y, ffExtras] = feed_forward(obj, x)
      value = compute_z(obj, x)
      value = compute_Dy(obj, ffExtras, y) % derivative of transfer function
      value = compute_D2y(obj, ffExtras, y, Dy) % second derivatie of transfer function
      push_to_GPU(obj)
      gather(obj)
      increment_params(obj, delta_params)
      init_params(obj)
   end
   
end

