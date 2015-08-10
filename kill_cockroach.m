function kill_cockroach
clc;clear;close all
%%
action = 'poison';
%%
t0 = 0;
tfinal = 40;
x0 = [100 30]';
tfinal = tfinal*(1+eps);
tau = 0.005;
handleFunc = @(t,x)pop(t,x);
iter = 1;
x = x0;
for t=t0:tau:tfinal
    if t==15
        switch action
            case 'none'
            case 'dump'
                x(1) = x(1)*0.00;
            case 'trap'
                handleFunc = @(t,x)pop_trap(t,x);
            case 'kill'
                x(2) = x(2)*0.01;
            case 'poison'
                tmp = zeros(4, 1);
                tmp(1) = x(1);
                num_infect = 1;
                tmp(2) = x(2) - num_infect;
                tmp(3) = num_infect;
                x = tmp;
                handleFunc = @(t,x)pop_SIR(t,x);
            otherwise
            	error('error action!')
        end      
    end
    [xnext] = RK4step(handleFunc,t,x,tau,4);
    xtrace(iter) = xnext(1);
    if numel(x) == 4
        ytrace(iter) = xnext(2) + xnext(3);
    else
        ytrace(iter) = xnext(2);
    end
    x = xnext;
    iter = iter + 1;
end

subplot(1,2,1)
plot(0:tau:tfinal,xtrace,0:tau:tfinal,ytrace)
legend('Amount of Trash', 'Cockroach Population')
title('Population vs. Time')
xlabel('Time');ylabel('amount')
subplot(1,2,2)
plot(xtrace, ytrace)
title([action, '-Phase Plant'])
xlabel('Amount of Trash');ylabel('Cockroach Population')
set(gcf, 'color', [1 1 1], 'unit', 'norm', 'pos', [0.2 0.2 0.7 0.5])
end

function dy = pop(t,y)
dy = zeros(2, 1);
dy(1) = y(1) * (1 - 1*y(1)/100) - 0.01 * y(1) * y(2);
dy(2) = -y(2) * (1 + 1*y(2)/50) + 0.03 * y(2) * y(1);
end

function dy = pop_trap(t,y)
dy = zeros(2, 1);
dy(1) = y(1) * (1 - y(1)/100) - 0.01 * y(1) * y(2);
dy(2) = -y(2) * (1 + y(2)/50) + 0.03 * y(2) * y(1) - 0.15 * y(2);
end

function dy = pop_SIR(t,y)
lambda = 0.2;
u = 0.3;
v = 0.00;
dy = zeros(4, 1); % trash/S/I/R
dy(1) = y(1) * (1 - y(1)/100) - 0.01 * y(1) * (y(2) + y(3));
dy(2) = -lambda * y(2) * y(3) + v - v * y(2) + 0.01 * y(2) * y(1);
dy(3) = lambda * y(2) * y(3) - u * y(3) - v * y(3) + 0.00 * y(3) * y(1);
dy(4) = u * y(3) - v * y(4);
end

function [Xnext] = RK4step(fun,t,X,h,opt)
    K1 = fun(t,X);
    if opt == 1
        Xnext = X + h*K1;
    else
        K2 = fun(t+h/2,X+h/2*K1);
        K3 = fun(t+h/2,X+h/2*K2);
        K4 = fun(t+h,X+h*K3);
        Xnext = X + h/6*(K1 + 2*K2 + 2*K3 + K4);
    end
end