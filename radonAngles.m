function theta = radonAngles(numInc,x);

numInc=x*numInc;
theta(1)=deg2rad(1);
thetaLast=deg2rad(89);
velocityHigh=1/tan(theta(1));
velocityLow=1/tan(thetaLast);

velInc = (velocityHigh - velocityLow)/numInc;

for i=1:x*173
    thetaNew=atan(1 / ((1/tan(theta(i))) - velInc));
    theta(i+1)=thetaNew;
end

theta = rad2deg(theta);

n=1;
for i=22:1/x:89,
    thetaLin(n)=i;
    n=n+1;
end

theta = [theta, thetaLin];