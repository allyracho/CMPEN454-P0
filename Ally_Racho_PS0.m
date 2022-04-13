clear;

%% Initial
% load image
I = imread('./banana_slug.tiff');

% check bits per int, width and height
class(I) % uint16, therefore 16 bits
imSize = size(I); % [2856, 4290]

% convert to double
I = double(I); 


%% Linerization
% convert to linear array
minval = 2047;
maxval = 15000;
lin_trans = (I-minval)/(maxval-minval);

% clip values
lin_trans = max(0, min(lin_trans, 1));


%% Bayer Pattern
% quarter-resolution sub-images
im1 = lin_trans(1:2:end, 1:2:end);
im2 = lin_trans(1:2:end, 2:2:end);
im3 = lin_trans(2:2:end, 1:2:end);
im4 = lin_trans(2:2:end, 2:2:end);

% quarter-resolution RGB images
im_grbg = cat(3, im2, im1, im3);
im_rggb = cat(3, im1, im2, im4);
im_bggr = cat(3, im4, im2, im1);
im_gbrg = cat(3, im3, im1, im2);

% brightening
figure; imshow(im_grbg * 4); title('grbg');
figure; imshow(im_rggb * 4); title('rggb'); % seems to look most natural
figure; imshow(im_bggr * 4); title('bggr');
figure; imshow(im_gbrg * 4); title('gbrg');


%% White Balancing
% pixels of each color channel
red = lin_trans(1:2:end, 1:2:end);
green1 = lin_trans(1:2:end, 2:2:end);
green2 = lin_trans(2:2:end, 1:2:end);
blue = lin_trans(2:2:end, 2:2:end);

% grey world balance
red_mean = mean(red(:));
green_mean = mean([green1(:); green2(:)]);
blue_mean = mean(blue(:));

% new image, assign white-balance values
im_gw = zeros(size(lin_trans));
im_gw(1:2:end, 1:2:end) = red * green_mean / red_mean;
im_gw(1:2:end, 2:2:end) = green1;
im_gw(2:2:end, 1:2:end) = green2;
im_gw(2:2:end, 2:2:end) = blue * green_mean / blue_mean;

% white world balance
red_max = max(red(:));
green_max = max([green1(:); green2(:)]);
blue_max = max(blue(:));

% new image, assign white-balance values
im_ww = zeros(size(lin_trans));
im_ww(1:2:end, 1:2:end) = red * green_max / red_max;
im_ww(1:2:end, 2:2:end) = green1;
im_ww(2:2:end, 1:2:end) = green2;
im_ww(2:2:end, 2:2:end) = blue * green_max / blue_max;


%% Demonsaicing
% red channel
[Y, X] = meshgrid(1:2:imSize(2), 1:2:imSize(1));
vals = im_ww(1:2:end, 1:2:end);

dms = zeros(size(im_ww));
dms(1:2:end, 1:2:end) = vals;

[Yin, Xin] = meshgrid(2:2:imSize(2), 1:2:imSize(1));
dms(2:2:end, 1:2:end) = interp2(Y, X, vals, Yin, Xin);
[Yin, Xin] = meshgrid(1:2:imSize(2), 2:2:imSize(1));
dms(1:2:end, 2:2:end) = interp2(Y, X, vals, Yin, Xin);
[Yin, Xin] = meshgrid(2:2:imSize(2), 2:2:imSize(1));
dms(2:2:end, 2:2:end) = interp2(Y, X, vals, Yin, Xin);

red_dms = dms;

% blue channel
[Y, X] = meshgrid(2:2:imSize(2), 2:2:imSize(1));
vals = im_ww(2:2:end, 2:2:end);

dms = zeros(size(im_ww));
dms(1:2:end, 2:2:end) = vals;

[Yin, Xin] = meshgrid(1:2:imSize(2), 1:2:imSize(1));
dms(1:2:end, 1:2:end) = interp2(Y, X, vals, Yin, Xin);
[Yin, Xin] = meshgrid(1:2:imSize(2), 2:2:imSize(1));
dms(1:2:end, 2:2:end) = interp2(Y, X, vals, Yin, Xin);
[Yin, Xin] = meshgrid(2:2:imSize(2), 1:2:imSize(1));
dms(2:2:end, 1:2:end) = interp2(Y, X, vals, Yin, Xin);

blue_dms = dms;

% green channel
[Y1, X1] = meshgrid(1:2:imSize(2), 2:2:imSize(1));
vals1 = im_ww(1:2:end, 2:2:end);

[Y2, X2] = meshgrid(2:2:imSize(2), 1:2:imSize(1));
vals2 = im_ww(2:2:end, 1:2:end);

dms = zeros(size(im_ww));
dms(1:2:end, 2:2:end) = vals1;
dms(2:2:end, 1:2:end) = vals2;


[Yin, Xin] = meshgrid(1:2:imSize(2), 1:2:imSize(1));
dms(1:2:end, 1:2:end) = (interp2(Y1, X1, vals1, Yin, Xin)... 
						+ interp2(Y2, X2, vals2, Yin, Xin)) / 2;
[Yin, Xin] = meshgrid(2:2:imSize(2), 2:2:imSize(1));
dms(2:2:end, 2:2:end) = (interp2(Y1, X1, vals1, Yin, Xin)...
						+ interp2(Y2, X2, vals2, Yin, Xin)) / 2;

green_dms = dms;

im_rgb = cat(3, red_dms, green_dms, blue_dms);


%% Brighten and Gamma Correction
% brighten
im_gray = rgb2gray(im_rgb);
percentage = 6;
im_rgb_brightened = im_rgb * percentage * max(im_gray(:));

% gamma correction
im_final = zeros(size(im_rgb_brightened));
inds = (im_rgb_brightened <= 0.0031308);
im_final(inds) = 12.92 * im_rgb_brightened(inds);
im_final(~inds) = real(1.055 * im_rgb_brightened(~inds) .^ (1 / 2.4) - 0.055);

figure; imshow(im_final)

%% Compress Image
imwrite(im_final, 'banana_slug.png', 'png');
imwrite(im_final, 'banana_slug.jpg','jpg', 'Quality', 95);

% compression ratio:
imfinfo('banana_slug.png') % compressed filesize == 24532559
size(im_final) % og filesize - (width * height * depth) / 8 == 4594590
ratio = 4594590 / 24532559

imfinfo('banana_slug.jpg') % compressed filesize == 5607807
ratio = 4594590 / 5607807

% ratio of png = 0.1873
% ratio of jpeg = 0.8193


% lowest setting for indistinguishable jpeg: 
imwrite(im_final, 'banana_slug_low.jpg', 'Quality', 0);

% compression ratio
imfinfo('banana_slug_low.jpg') % file size == 224771
ratio = 4594590 / 224771
% ratio of indistinguishable jpeg = 20.4412

