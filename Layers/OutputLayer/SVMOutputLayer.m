classdef SVMOutputLayer < StandardOutputLayer
   % A linear output layer with a hinge loss function raised to the power 
   % lossExponent. Requires targets to take values {-1, 1} (as opposed to 
   % {0, 1} for LogisticOutputLayer). If left unspecified, maxFanIn is set
   % to 1/sqrt(L2Penalty) as optimal solution must lie in this ball.
   
   properties
      costRatio % multiplies the loss for misclassifying positive examples
      lossExponent % exponent of the hinge loss function (> 1)
   end
   
   methods
      function obj = SVMOutputLayer(inputSize, outputSize, varargin)
         obj = obj@StandardOutputLayer(inputSize, outputSize, varargin{:});
         p = inputParser();
         p.KeepUnmatched = true;
         p.addParamValue('lossExponent', 2, @(x) x > 1)
         p.addParamValue('costRatio', 1);
         parse(p, varargin{:});
         obj.lossExponent = p.Results.lossExponent;
         obj.costRatio = p.Results.costRatio;
         
         if ~isempty(obj.L2Penalty) && isempty(obj.maxFanIn)
            obj.maxFanIn = 1/sqrt(obj.L2Penalty);
         end
      end
         
      function [dLdz, y] = compute_dLdz(obj, x, t)
         y = obj.feed_forward(x);
         if obj.costRatio == 1
            dLdz = -obj.lossExponent*t.*(max(1 - y.*t, 0).^(obj.lossExponent-1));
         else % obj.costRatio~= 1 (costRatio should not be used if outputSize>1)
            posIdx = t==1;
            negIdx = t~=1;
            tPos = t(posIdx);
            yPos = y(posIdx);
            tNeg = t(negIdx);
            yNeg = y(negIdx);
            dLdz = obj.gpuState.zeros(size(y));
            dLdz(:,posIdx) = -obj.lossExponent*obj.costRatio*...
                          tPos.*(max(1 - yPos.*tPos, 0).^(obj.lossExponent-1));
            dLdz(:,negIdx) = -obj.lossExponent*tNeg.*...
                             (max(1 - yNeg.*tNeg, 0).^(obj.lossExponent-1));
         end
      end
      
      function y = feed_forward(obj, x)
         y = obj.compute_z(x);
      end
      
      function loss = compute_loss(obj, y, t)
         if obj.costRatio == 1
            loss = sum(max(1 - y(:).*t(:), 0).^obj.lossExponent)/size(y, 2);
         else % costRatio ~= 1 (costRatio should not be used if outputSize > 1)
            posIdx = t==1;
            negIdx = t~=1;
            tPos = t(posIdx);
            yPos = y(posIdx);
            
            tNeg = t(negIdx);
            yNeg = y(negIdx);
            
            loss = mean([obj.costRatio*max(1 - yPos.*tPos, 0).^obj.lossExponent, ...
                           max(1 - yNeg.*tNeg, 0).^obj.lossExponent]);
         end
      end
   end
   
end