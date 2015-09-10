#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "MRRepetitionEstimator.h"
#import <vector>
#import <experimental/optional>

@implementation MRRepetitionsEstimator

- (std::vector<double>)autocorrelation:(const std::vector<double>&)data {
    size_t filterLength = data.size();
    size_t resultLength = filterLength;
    size_t signalLength = 2 * filterLength - 1;
    std::vector<double> correlation = std::vector<double>(resultLength);
    std::vector<double> signal = std::vector<double>(signalLength);
    signal.insert(signal.begin(), data.begin(), data.end());

    vDSP_convD(signal.data(), vDSP_Stride(1), data.data(), vDSP_Stride(1), correlation.data(), vDSP_Stride(1), vDSP_Length(resultLength), vDSP_Length(filterLength));

    double max = 2.0 / correlation[0];
    double shift = -1;
    vDSP_vsmsaD(correlation.data(), vDSP_Stride(1), &max, &shift, correlation.data(), vDSP_Stride(1), vDSP_Length(correlation.size()));
    
    return correlation;
}

- (uint)numberOfRepetitions:(const cv::Mat&)data {
    uint N = data.cols;
    std::vector<double> summedCorr = std::vector<double>(N);

    for (uint i = 0; i < data.rows; ++i) {
        std::vector<double> rv = std::vector<double>(data.cols);
        for (uint j = 0; j < data.cols; ++j) rv.push_back(data.at<int16_t>(i, j));
        std::vector<double> correlation = [self autocorrelation:rv];
        vDSP_vaddD(summedCorr.data(), vDSP_Stride(1), correlation.data(), vDSP_Stride(1), summedCorr.data(), vDSP_Stride(1), vDSP_Length(N));
    }

    std::vector<uint> peaks = [self findPeaks:summedCorr];
    uint repetitions = [self guessNumberOfRepetitions:peaks withMinPeakDistance:25];
    return repetitions;
}

- (std::vector<uint>)findPeaks:(const std::vector<double>&)data {
    const uint nDowns = 1;
    const uint nUps = 1;
    std::vector<uint> peaks;

    for (uint i = nDowns; i < data.size() - nUps - 1; ++i) {
        bool isPeak = true;
        for (int j = -nDowns; j < nUps - 1; ++j) {
            if (j < 0) isPeak = isPeak && data[i + j] <  data[i + j + 1];
            else       isPeak = isPeak && data[i + j] >= data[i + j + 1];
        }
        if (isPeak) peaks.push_back(i);
    }
    
    return peaks;
}

- (uint)guessNumberOfRepetitions:(std::vector<uint>&)peakLocations withMinPeakDistance:(uint)distance {
    if (peakLocations.empty()) return 0;
    for (uint i = 0; i < peakLocations.size() - 2; ++i) {
        if (peakLocations[i + 1] - peakLocations[i] < distance) return i + 1;
    }
    return static_cast<uint>(peakLocations.size());
}

- (uint)estimate:(const std::vector<muvr::fused_sensor_data>&)data {
    auto firstData = data.front();
    return [self numberOfRepetitions:firstData.data];
}

@end
