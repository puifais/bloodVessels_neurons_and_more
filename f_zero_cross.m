function nzero = f_zero_cross(data)


n  = length(data);
nzero = [];
for i = 2:n
      if data(i) * data(i-1) < 0 ; % have zero cross
            nzero = [nzero, 1];
      elseif data(i) * data(i-1) == 0;% may have zerocross
            if data(i) ==0 & data(i-1) ==0
                  nzero = [nzero,0];
            elseif data(i) ~= 0
                  nzero = [nzero,1];
            elseif data(i-1) ~=0
                  nzero = [nzero,1];
            end
      elseif data(i) * data(i-1) > 0; % no zero cross
            nzero = [nzero, 0];
      end
end% loop

% figure
% plot(data, '-k'); hold on
% plot(line, 'b');
% plot(nzero*100, 'r.')