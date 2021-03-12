classdef Particle
    properties
        x; % x position
        y; % y position
        w; % weight
        
        % landmarks
        rgbPos; % landmarks positions, dim:(3,2);  ex: [Rx Ry; Gx Gy; Bx By]
        rgbCov; % x positions' covariance, dim:(3,3); 
        
        singularPoint;
        numUpdates; % number of updates
    end
    
    methods
        function obj = Particle(x_,y_,varargin)
            obj.x = x_;
            obj.y = y_;
            
            obj.singularPoint = 1e-6;
            obj.numUpdates = 0;
            
            if nargin == 3
                obj.w = varargin{1};
            elseif nargin == 5
                obj.w = varargin{1};
                obj.rgbPos = varargin{2};
                obj.rgbCov = varargin{3};               
            end
        end
        
        function obj = move(obj, dx, dy)
            obj.x = obj.x + dx + (rand*0.06-0.03);
            obj.y = obj.y + dy + (rand*0.06-0.03);
        end
        
        function obj = addNewLm(obj, U, Z, lmY)
            % z: distance between the particle and the lm
            dX2 = Z.^2 - (lmY-obj.y).^2;
            im = dX2 < 0;
            dX2(dX2<0) = 0; 
            
            if obj.numUpdates == 1
                obj.rgbPos(:,1) = sqrt(dX2);
                obj.rgbCov = diag((0.2+1.0*im));
            end
            
%             lmX = obj.x + sign*sqrt(dX2);
%             obj.rgbPos(:,1) = lmX;
%             obj.rgbCov = (0.5+1.0*im)*diag([1,1,1]);
            
        end
        
        function obj = updateLandmark(obj, Z, R)
            % update by EKF
            P = obj.rgbCov; % covariance matrix
            [H,dx,dy] = obj.computeJacobian(); % H: jacobian of h(x_k)
            Qz = H*P*H' + R; % Qz: measurement covariance; R: measurement noise
            if det(Qz) < obj.singularPoint
                QzInv = pinv(Qz);
            else
                QzInv = inv(Qz);
            end
            
            K = P*H'*QzInv; % Kalman Gain
            Z_hat = sqrt(dx.^2 + dy.^2);
            dZ = Z - Z_hat;
            
            % update the states and the covariance
            obj.rgbPos(:,1) = obj.rgbPos(:,1) + K*dZ;
            obj.rgbCov = (eye(3) - K*H)*P;
            
        end
        
        function [H, dx, dy] = computeJacobian(obj)
            % Compute the H matrix in EKF
            dx = obj.rgbPos(:,1) - obj.x;
            dy = obj.rgbPos(:,2) - obj.y;
            H = diag(dx./sqrt(dx.^2+dy.^2)); % H: jacobian of h(x_k)
        end
        
        function w = computeWeight(obj, Z, R)
            P = obj.rgbCov; % covariance matrix
            [H, dx, dy] = obj.computeJacobian(); % H: jacobian of h(x_k)
            Qz = H*P*H' + R; % Qz: measurement covariance; R: measurement noise
            if det(Qz) < obj.singularPoint
                % singular
                w = 1.0;
                return;
            end
   
            Z_hat = sqrt(dx.^2 + dy.^2);
            dZ = Z - Z_hat;

            w = exp(-0.5*dZ'*(Qz\dZ)) / (2*pi*sqrt(det(Qz)));
            
            return;
        end
            
        
        
    end
end