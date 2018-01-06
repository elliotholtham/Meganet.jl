export SoftmaxLoss, getLabels, getMisfit

"""
sofmax loss function
"""
type SoftmaxLoss
    shift
    theta
    addBias
    SoftmaxLoss(shift=0.0, theta=1e-3, addBias=true) = new(shift,theta,addBias)
end

import Base.display
display(this::SoftmaxLoss) = println("SoftmaxLoss(shift$(this.shift),theta=$(this.theta),addBias=$(this.addBias))")

function getMisfit(this::SoftmaxLoss,W,Y,C,doDY=true,doDW=true)

    dWF = zeros(0); d2WF = zeros(0); dYF =zeros(0); d2YF = zeros(0)

    szY  = size(Y)
    nex  = szY[2]
    if this.addBias
        Y   = [Y; ones(1,nex)]
    else
        Y   = copy(Y)  # make sure we don't overwrite features
    end

    szW  = [size(C,1),size(Y,1)]

    W   = reshape(W,tuple(szW...))
    Y   -= this.shift

    S   = exp.(W*Y)

    Cp   = getLabels(this,S)
    err  = countnz(C-Cp)/2
    F    = -sum(sum(C.*(W*Y))) + sum(log.(sum(S,1)))
    para = [F,nex,err]
    F   /= nex

    if doDW || doDY
        dF   = -C + S./sum(S,1)
        d2F  = U -> this.theta *U + (U.*S)./sum(S,1) -
                    S.*(repmat(sum(S.*U,1)./sum(S,1).^2,size(S,1),1))
    end
    if doDW
        dWF  = vec(dF*(Y'/nex))
        matW      = W -> reshape(W,tuple(szW...))
        d2WFmv    = U -> vec((d2F(matW(U/nex)*Y)*Y'))
        d2WF      = LinearOperator(prod(szW),prod(szW),true,true,d2WFmv)
    end
    if doDY
        if this.addBias
            W = W[:,1:end-1]
        end
        dYF  =   vec(W'*dF)/nex

        WI     = T -> W*T
        WIT    = T -> W'*T
        matY   = Y -> reshape(Y,szY)
        d2YFmv = T -> vec(WIT(((d2F(WI(matY(T/nex)))))))

        d2YF = LinearOperator(prod(szY),prod(szY),true,true,d2YFmv)
    end
    return F, para, dWF, d2WF, dYF, d2YF
end

function getLabels(this::SoftmaxLoss,W,Y=nothing)
    if Y==nothing
        S = W
        nex = size(S,2)
    else
        ny = size(Y); nf = ny[1]; nex = ny[2]
        if this.addBias
            W      = reshape(W,:,nf+1)
            Y     = [Y; ones(1,nex)]
        end
        Y     = Y - this.shift
        S      = exp.(W*Y)
    end
    P      = S./sum(S,1)
    Cp     = zeros(size(P))
    for i=1:size(P,2)
        Cp[indmax(P[:,i]),i] = 1
    end
    return Cp
end
