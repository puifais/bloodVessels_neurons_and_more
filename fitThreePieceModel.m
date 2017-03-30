function RES = fitThreePieceModel(x, y, cut1, cut2, polyOrder, useGaussianAtMiddle)

    showDebug = 0;
%1. fit the left and right
    x1 = x(1:cut1);
    y1 = y(1:cut1);
        
    [p1, S] = polyfit(x1,y1,polyOrder);
    y1Hat = polyval(p1, x1);
    
    x2 = x(cut2:end);
    y2 = y(cut2:end);
    [p2, S] = polyfit(x2,y2,polyOrder);
    y2Hat = polyval(p2, x2);
    
%2. fit the center Gaussian    
    x3 = x(cut1+1: cut2-1);
    y3 = y(cut1+1: cut2-1);    

    if  useGaussianAtMiddle ~= 1 % 1 is special case, fit Gaussian
         if useGaussianAtMiddle == 0, useGaussianAtMiddle = 2;, end;
         [p3, S] = polyfit(x3,y3, useGaussianAtMiddle); %use quadratic func to fit instead (fast!)
         y3Hat = polyval(p3, x3);        
         coefEsts = p3;
    else
        %p(3)=gain, p(2)=std, p(1) = mean
        modelFun = @(p,x) (p(3)./(p(2).*2.5066) ) .*exp(-( (x - p(1)).^2 ./(2.*p(2).^2)) );
        %2.5066 is sqrt(2*pi)
        %This is the inital guess for the Gaussian parameters (may be  %improved...)
        startingVals = [(cut1+cut2).*0.5 (cut2-cut1).*0.5 max(y3)];    
        coefEsts = nlinfit(x3, y3, modelFun, startingVals);
        y3Hat = modelFun(coefEsts,x3);
    end
    
    %report the error, and the result
    yHat = [ y1Hat y3Hat y2Hat];
    LeastSQ_err = norm( y - yHat);
    
    RES.leastSQ_err = LeastSQ_err;
    RES.yHat = yHat;
    RES.param1 = p1;
    RES.param2 = p2;
    RES.paramGaussian = coefEsts;
    RES.cut = [cut1 cut2];
    
    if showDebug == 1
        figure; 
        hold on;
        plot(x, y);
        plot(x, yHat, 'r-');
        hold off;
        %df
    end
    
end
