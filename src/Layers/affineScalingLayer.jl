export AffineScalingLayer

"""
Scales and shifts the 3D feature tensor along each dimension. This is
useful, e.g., in batch normalization.

kron(s3,kron(s2,s1)) * vec(Y) + kron(b3,kron(e2,e1)) +
kron(e3,kron(b2,e1)) + kron(e3,kron(e2,b1));
"""
type AffineScalingLayer <: AbstractMeganetElement
    nData       # describe size of data, at least first two dim must be correct.
end

function splitWeights(this::AffineScalingLayer,theta)
    theta = reshape(theta,:,2)
    s2    = theta[:,1]
    b2    = theta[:,2]
    return s2, b2
end

function scaleChannels(Y,s,b)
    for i=1:length(s)
        Y[:,i,:] = s[i]*Y[:,i,:] + b[i]
    end
    return Y
end

function apply(this::AffineScalingLayer,theta,Y,doDerivative=false)

    Y   = reshape(Y,this.nData[1], this.nData[2],:)
    dA  = []
    nex = size(Y,3)

    s2,b2 = splitWeights(this,theta);

    Y = scaleChannels(Y,s2,b2);

    Y = reshape(Y,:,nex)
    Ydata = Y
    return Ydata, Y, dA
end


function nTheta(this::AffineScalingLayer)
    return 2*this.nData[2]
end

function nFeatIn(this::AffineScalingLayer)
    return prod(this.nData[1:2])
end

function nFeatOut(this::AffineScalingLayer)
   return prod(this.nData[1:2])
end

function nDataOut(this::AffineScalingLayer)
    return nFeatOut(this);
end

function initTheta(this::AffineScalingLayer)
    s2,b2 = splitWeights(this,ones(nTheta(this)))
    return  [s2[:]; 0*b2[:]]
end

function Jthetamv(this::AffineScalingLayer,dtheta,theta,Y,tmp=nothing)

    Y   = reshape(copy(Y),this.nData[1], this.nData[2],:)
    nex = size(Y,3)

    ds2,db2 = splitWeights(this,dtheta)
    dY      = scaleChannels(Y,ds2,db2)

    dY = reshape(dY,:,nex)
    dYdata = dY
    return dYdata, dY
end

function JthetaTmv(this::AffineScalingLayer,Z,dummy,theta,Y,tmp=nothing)
    Y   = reshape(Y,this.nData[1], this.nData[2],:)
    Z   = reshape(Z,this.nData[1], this.nData[2],:)

    W = Y.*Z

    dtheta = vec(sum(sum(W,1),3))
    return  [dtheta; vec(sum(sum(Z,1),3))]
end

function JYmv(this::AffineScalingLayer,dY,theta,Y,tmp=nothing)

    dY   = reshape(copy(dY),this.nData[1], this.nData[2],:);
    nex = size(dY,3)

    s2,b2 = splitWeights(this,theta);
    dY    = scaleChannels(dY,s2,b2*0)

    dY     = reshape(dY,:,nex)
    dYdata = dY
    return dYdata, dY
end

function JYTmv(this::AffineScalingLayer,Z,dummy,theta,Y,tmp=nothing)

    Z   = reshape(copy(Z),this.nData[1], this.nData[2],:)
    nex = size(Z,3)

    s2,b2 = splitWeights(this,theta)
    Z     = scaleChannels(Z,s2,b2*0)
    return reshape(Z,:,nex)
end