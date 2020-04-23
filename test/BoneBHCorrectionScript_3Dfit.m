% %% simulate data
% addpath(genpath(pwd));
% CTsimulation('.\system\mod\Ryan_configure.xml')

%% reconstruct to get image
% img=CTrecon('E:\matlab\Data\Calibration\BoneBH\recon_Axial_Head_All_120KV300mA_SmallFocalQFS_1SecpRot.xml');
% save('img.mat','img');
% imtool(img{1}(:,:,32)', [950 1050]);

%% set forward projection para
clear all; 
clc;
load('E:\matlab\Data\PX\2.1584078847542_headaxial_N\img.mat');
addpath(genpath('E:\CRIS_v1.0'));
FPStruct.bIsVAntiCW = 0;                                 % ͶӰɨ�跽��0:clockwise, 1:counterclockwise
FPStruct.bIsCAntiCW = 0;                                 % ̽�����Ų�����0:clockwise, 1:counterclockwise
FPStruct.fFPStAng = 0;                                   % ͶӰ��ʼ�Ƕ�
FPStruct.fFPAng = 360;                                   % ͶӰ�ܽǶȷ�Χ
FPStruct.nFPViewNum = 1152;                              % ͶӰ��������
FPStruct.nChaNum = 900;                              % ̽����ͨ����
FPStruct.fCenCha = FPStruct.nChaNum/2;            % ̽��������ͨ��
FPStruct.fSysFov = 500;% ̽�������ǵ�ɨ��Ұ
FPStruct.fReconFov = 200;  % ͼ���ؽ���Χ
FPStruct.fReconCenX = 0;                                 % ͼ���������ڿռ�X����
FPStruct.fReconCenY = 0;                                 % ͼ���������ڿռ�Y����
FPStruct.nSampleNum = 1000;                              % ԭ�㷨ʹ�ã����������ˣ�ռλ

%% get Bone Density Image
Image =img{1};
BoneImage = zeros(size(Image),'single');
thres=1200;
BoneMax=3000;
idx=Image>=thres;
BoneImage(Image>=thres) = (Image(idx)-1000)./(BoneMax-1000).*Image(idx);

%% load BoneBH cortable and calculate corresponding parameters
% strCortblpath ='E:\matlab\Data\Calibration\BoneBH\BHtemp.mat';
strCortblpath2 = 'E:\matlab\Data\PX\calibration\BoneBH\BHtemp.mat';

stBoneBHPara = BoneBHPrepare(strCortblpath, FPStruct);
stBoneBHPara2 = BoneBHPrepare2(strCortblpath2, FPStruct);

%% forward projection
Engine = EngineManager.GetInstance('GPUCompute');
func = Engine.GetFunction('PForeProjectionCU');

nImgNum=size(img{1},3);
nImgSize=size(img{1},1);

CorrProj = zeros(FPStruct.nChaNum,nImgNum,FPStruct.nFPViewNum,'single');
% loop all the Images
for kk=1:nImgNum
    ImgProjTemp = func(Image(:,:,kk), nImgSize, FPStruct);
    BoneProjTemp = func(BoneImage(:,:,kk), nImgSize, FPStruct);

% Calculate Db
    Db = CalcDb(ImgProjTemp,BoneProjTemp,stBoneBHPara);
% BoneBH Correction    
%     CorrProj(:,kk,:)=1000*Db.*stBoneBHPara.murefb./stBoneBHPara.murefw - BoneProjTemp;
    
    Dfix = CalcDb2(ImgProjTemp,BoneProjTemp,stBoneBHPara2);
    CorrProj(:,kk,:) = Dfix;
end

%% ���
%�����ʹ�õ����������ֵ,Ϊ�˵���CRIS��Conv����Ҫ����ȫ�ֱ����ṹ�壬ֱ��ʹ�ö�Ӧ���͵������ݵ�xml�����ɽṹ�塣
gParas_Inside = Global_Parameter('E:\matlab\CT\SINO\TM\2.1574328929606.pd.2.1574328929608.xml');
%������ͶӰ���������½ṹ�����
gParas_Inside.VariableParameters.ChannelNumPar = FPStruct.nChaNum;
gParas_Inside.VariableParameters.ChannelParSpace = FPStruct.fSysFov/FPStruct.nChaNum; %ȷ�����Ƿ���ȷ
gParas_Inside.ReconParameters.reconKernel = 'Bone';

subConv = Conv('Conv', 'GlobalParameter', gParas_Inside, 'DebugSave', 0, 'ProcessType', 'Matlab');
subConv.Init(gParas_Inside);

struct_raw_Inside.data = CorrProj;
struct_raw_Inside.raw_size = [size(struct_raw_Inside.data, 1), size(struct_raw_Inside.data, 2), size(struct_raw_Inside.data, 3)];
struct_raw_Inside.header.viewAngle = -90;   % ����ͶӰ�����õ��Ŀⲻ�ǲ���ͬһ������ϵ��������Ҫ��ʱ��ƫת90��

run_struct_Inside = [];
[struct_raw_Inside, run_struct_Inside] = subConv.Process(struct_raw_Inside, run_struct_Inside);

%% ��ͶӰ
BpStruct = BuildBpStruct(FPStruct);
fViewWeight = ones(BpStruct.nTotalViewNumber, 1, 'single')*0.5;
ImgNum_pZ = BpStruct.nSliceNumber;

func = Engine.GetFunction('Axial2DBP_CU');
CorrImage = func(struct_raw_Inside.data,fViewWeight,BpStruct,ImgNum_pZ);
% rot back
CorrImage=rot90(CorrImage,-1);

%% check the result
imgbyBBHCor=img{1}+CorrImage;

imtool(img{1}(:,:,32),[975 1025]);
imtool(imgbyBBHCor(:,:,32),[975 1025]);
imtool(CorrImage(:,:,32),[-25 25]);

figure();
plot(img{1}(256,:,32))
hold on
plot(imgbyBBHCor(256,:,32))
grid on

%% functions
%CalcDb
function Db = CalcDb(D,Dw_d,stBoneBHPara)

    ImgProjTemp=D./1000;
    BoneProjTemp=Dw_d./1000;
    
    u = stBoneBHPara.u;
    v = stBoneBHPara.v;    
    x = stBoneBHPara.x;
    nChannelNum = stBoneBHPara.nChannelNum;
% 	idxL = BoneBHStruct.idxL;
%     fChannelPosMOD = BoneBHStruct.fChannelPosMOD;
%     Nres = BoneBHStruct.Nres;
    % BoneBHStruct.murefw = murefw;
    % BoneBHStruct.murefb =murefb;
    [nCh,nView] = size(D);
    Db = zeros(nCh,nView);
    D_poly = ones(nCh,nView,v);
    Db_poly = ones(nCh,nView,u);
    %Bone BHcorrection
    for ii = 2:v
        D_poly(:,:,ii) = (ImgProjTemp).^(ii-1);
    end

    for jj = 2:u
        Db_poly(:,:, jj) = (BoneProjTemp).^(jj-1);
    end

    for mm=1:nChannelNum
    %ʹ�ò�ͬ�������֮���ٲ�ֵ����Db
    % BoneBHCoefL= squeeze(D_poly(mm,:,:)) * x(:,:,idxL(mm))'; 
    % BoneBHCoefR= squeeze(D_poly(mm,:,:)) * x(:,:,idxL(mm)+1)'; 
    % temp=squeeze(Db_poly(mm,:,:));
    % DbL=sum(BoneBHCoefL.*temp,2);
    % DbR=sum(BoneBHCoefR.*temp,2);
    % Db(mm,:)= (1-fChannelPosMOD(mm))*DbL+fChannelPosMOD(mm)*DbR;
    % x_interp=(1-fChannelPosMOD(mm))*x(:,:,idxL(mm))+ fChannelPosMOD(mm)* x(:,:,idxL(mm)+1);
    x_mm=x(:,:,mm);
    BoneBHCoef= squeeze(D_poly(mm,:,:)) * x_mm'; 
    temp=squeeze(Db_poly(mm,:,:));
    Db(mm,:)=sum(BoneBHCoef.*temp,2);
    end    
end


function Dfix = CalcDb2(D, Db, stBoneBHPara)

Dscale = 1/stBoneBHPara.HCscale/stBoneBHPara.Dscale;
bonescale = 1/stBoneBHPara.HCscale/stBoneBHPara.bonescale;
Dbcurve = polyval3dm(stBoneBHPara.curvematrix, D.*Dscale, Db.*bonescale, stBoneBHPara.efffilter);
Dfix = (Dbcurve.*stBoneBHPara.mubonmuw-1).*Db;

end


function BoneBHStruct = BoneBHPrepare(strCortblpath,FPStruct)
BoneBHCorr=load(strCortblpath);
x=BoneBHCorr.head{1, 3}{1, 1}.main;
murefw=BoneBHCorr.head{1, 3}{1, 1}.refrencemu;
murefb=0.0402476502011957; %��ʱ��ֵ��������Ҫ��У�����ж�ȡ
Nres=BoneBHCorr.head{1, 3}{1, 1}.Nres;

%�ҳ�ÿ��ͨ����Ҫʹ�õ�У����λ��
fChannelSpace=FPStruct.fSysFov / FPStruct.nChaNum;
nChannelNum=FPStruct.nChaNum;
fMidChannel=FPStruct.fCenCha;
fChannelPos = ((1:nChannelNum)-fMidChannel)*fChannelSpace;
nChannelPosL=floor(fChannelPos);
fChannelPosMOD=fChannelPos-nChannelPosL;

MinfChannelPos_Cor = -257;
MaxfChannelPos_Cor = 253;
xpermute=permute(x, [3 1 2] );

%����̶���ͶӰͨ����Ϊ1000����
%xinterp=interp1(-249.5:0.5:250,xpermute,fChannelPos);

xinterp=interp1(MinfChannelPos_Cor:0.5:MaxfChannelPos_Cor,xpermute,fChannelPos);
xinterp = permute(xinterp, [2,3,1] );
idxL=nChannelPosL-MinfChannelPos_Cor+1;

BoneBHStruct.x = xinterp;
BoneBHStruct.idxL = idxL;
BoneBHStruct.fChannelPosMOD = fChannelPosMOD;
BoneBHStruct.Nres = Nres;
BoneBHStruct.murefw = murefw;
BoneBHStruct.murefb =murefb;
BoneBHStruct.nChannelNum=nChannelNum;
BoneBHStruct.u = size(xinterp,1);
BoneBHStruct.v = size(xinterp,2);
end

function BoneBHStruct = BoneBHPrepare2(strCortblpath, FPStruct)
% load table
BoneBHCorr=load(strCortblpath);

%�ҳ�ÿ��ͨ����Ҫʹ�õ�У����λ��
fChannelSpace=FPStruct.fSysFov / FPStruct.nChaNum;
nChannelNum=FPStruct.nChaNum;
fMidChannel=FPStruct.fCenCha;
fChannelPos = ((1:nChannelNum)-fMidChannel)*fChannelSpace;

% prepare
BoneBHStruct.efffilter = interp1(BoneBHCorr.beamposition, BoneBHCorr.effbeamfilter, fChannelPos, 'linear', 'extrap');
BoneBHStruct.efffilter = BoneBHStruct.efffilter(:)./BoneBHCorr.curvescale(3);
BoneBHStruct.curvematrix = reshape(BoneBHCorr.curvematrix, BoneBHCorr.order);
BoneBHStruct.Dscale = BoneBHCorr.curvescale(1);
BoneBHStruct.bonescale = BoneBHCorr.curvescale(2);
BoneBHStruct.mubonmuw = BoneBHCorr.refrencebonemu/BoneBHCorr.refrencemu;
BoneBHStruct.HCscale = 1000;

end


function BpStruct = BuildBpStruct(FPStruct)
BpStruct.nRotateDirection    = 1 - 2*double(FPStruct.bIsVAntiCW);
BpStruct.nViewPerRevolution  = FPStruct.nFPViewNum;
BpStruct.nTotalViewNumber    = FPStruct.nFPViewNum;
BpStruct.fStartAngle         = FPStruct.fFPStAng;
BpStruct.nChannelDirection   = -1 + 2*double(FPStruct.bIsCAntiCW);
BpStruct.nChannelNumPar      = FPStruct.nChaNum;
BpStruct.fChannelParSpace    = FPStruct.fSysFov / FPStruct.nChaNum;
BpStruct.fMidChannelPar      = FPStruct.fCenCha + 1;
BpStruct.nSliceDirection     = 1;
BpStruct.nSliceNumber        = 64;                  %��Ҫ��Ϊ�� SYS�е�ֵ
BpStruct.fSliceSpace         = 0.625;               %��Ҫ��Ϊ�� SYS�е�ֵ
% BpStruct.nCouchDirection     = gParas.AcquisitionParameter.tableDirection; % Add for 3DBP
% BpStruct.fSourseToIsocenter  = gParas.GeometryParameter.sourceToIso; % Add for 3DBP
BpStruct.fTiltAngle          = 0;
BpStruct.fZDFS               = 0; % zDFS ����¹�Դ����ż��Viewλ���������Viewλ�õľ���
BpStruct.fMaxFOV             = FPStruct.fSysFov;
BpStruct.fReconFOV           = FPStruct.fReconFov;
BpStruct.nXPixels            = 512;
BpStruct.nYPixels            = 512;
BpStruct.fXReconCenter       = FPStruct.fReconCenX;
BpStruct.fYReconCenter       = FPStruct.fReconCenY;
% BpStruct.fImageThickness     = gParas.ReconParameters.ImageThickness; % Add for 3DBP, NO Using
% BpStruct.fImageIncrement     = gParas.ReconParameters.ImageIncrement; % Add for 3DBP
BpStruct.nImageNumber        = BpStruct.nSliceNumber;
end