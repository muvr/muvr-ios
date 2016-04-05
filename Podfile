platform :ios, '9'
use_frameworks!

def muvrkit_pods
   pod 'PebbleKit'
end

def muvr_pods
   muvrkit_pods
   pod 'Charts', '~> 2'
   pod 'JTCalendar', '~> 2'
   # pod 'MBCircularProgressBar'
   pod 'DGRunkeeperSwitch', '~> 1.1'
   # pod 'ProgressKit' <- various progress bars & circles
   # pod 'Reachability' <- network reachability
end


target 'Muvr' do
    muvr_pods
end
 
target 'MuvrKit iOS' do
    muvrkit_pods
end

target 'MuvrKitTests' do
    muvrkit_pods
end

target 'MuvrTests' do
    muvr_pods
end

target 'MuvrUITests' do
    muvr_pods
end
