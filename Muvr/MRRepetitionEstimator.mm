#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "MRRepetitionEstimator.h"
#import <vector>
#import <experimental/optional>

@implementation MRRepetitionEstimator

- (std::vector<double>)autocorrelation:(const std::vector<double>&)data {
    /*
     let filterLength = data.count
     let resultLength = filterLength
     var correlation = [Double](count:resultLength, repeatedValue: 0)
     let signal = data + [Double](count:filterLength - 1, repeatedValue: 0)
     
     vDSP_convD(signal, vDSP_Stride(1), data, vDSP_Stride(1), &correlation, vDSP_Stride(1), vDSP_Length(resultLength), vDSP_Length(filterLength))
     
     // Convert into [-1, 1]
     var max: Double = 2 / correlation[0]
     var shift: Double = -1
     vDSP_vsmsaD(correlation, vDSP_Stride(1), &max, &shift, &correlation, vDSP_Stride(1), vDSP_Length(correlation.count))
     
     return correlation
     */
    
    size_t filterLength = data.size();
    size_t resultLength = filterLength;
    size_t signalLength = 2 * filterLength - 1;
    std::vector<double> correlation = std::vector<double>(resultLength, 0.0);
    std::vector<double> signal = std::vector<double>(signalLength, 0.0);
    signal.insert(signal.begin(), data.begin(), data.end());

    vDSP_convD(signal.data(), vDSP_Stride(1), data.data(), vDSP_Stride(1), correlation.data(), vDSP_Stride(1), vDSP_Length(resultLength), vDSP_Length(filterLength));

    double max = 2.0 / correlation[0];
    double shift = -1;
    vDSP_vsmsaD(correlation.data(), vDSP_Stride(1), &max, &shift, correlation.data(), vDSP_Stride(1), vDSP_Length(correlation.size()));
    
    return correlation;
}

- (uint)numberOfRepetitions:(const cv::Mat&)data {
    uint N = data.rows;
    std::vector<double> summedCorr = std::vector<double>(N, 0.0);

    for (uint i = 0; i < data.cols; ++i) {
        std::vector<double> rv = std::vector<double>(data.rows);
        for (uint j = 0; j < data.rows; ++j) rv.push_back(data.at<int16_t>(j, i));
        std::vector<double> correlation = [self autocorrelation:rv];
        vDSP_vaddD(summedCorr.data(), vDSP_Stride(1), correlation.data(), vDSP_Stride(1), summedCorr.data(), vDSP_Stride(1), vDSP_Length(N));
    }

    std::vector<uint> peaks = [self findPeaks:summedCorr];
    uint repetitions = [self guessNumberOfRepetitions:peaks withMinPeakDistance:25];
    return repetitions;
}

- (std::vector<uint>)findPeaks:(const std::vector<double>&)data {
    const int nDowns = 1;
    const int nUps = 1;
    std::vector<uint> peaks;

    for (uint i = nDowns; i < data.size() - nUps; ++i) {
        bool isPeak = true;
        for (int j = -nDowns; j < nUps; ++j) {
            if (j < 0) isPeak = isPeak && data[i + j] <  data[i + j + 1];
            else       isPeak = isPeak && data[i + j] >= data[i + j + 1];
        }
        if (isPeak) peaks.push_back(i);
    }
    
    return peaks;
}

- (uint)guessNumberOfRepetitions:(std::vector<uint>&)peakLocations withMinPeakDistance:(uint)distance {
    if (peakLocations.size() <= 1) return 0;
    for (uint i = 0; i < peakLocations.size() - 2; ++i) {
        if (peakLocations[i + 1] - peakLocations[i] < distance) return i + 1;
    }
    return static_cast<uint>(peakLocations.size());
}

- (uint)estimate:(const std::vector<muvr::fused_sensor_data>&)data {
    if (data.empty()) return 0;
    auto firstData = data.front();
    return [self numberOfRepetitions:firstData.data];
}

@end
