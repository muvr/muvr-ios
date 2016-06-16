platform :ios, '10'
use_frameworks!

def muvrkit_pods
   pod 'PebbleKit'
end

def muvr_pods
   muvrkit_pods
   # Charts is not Swift 3.0
   # pod 'Charts', '~> 2'
   #
   pod 'JTCalendar', '~> 2'
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
