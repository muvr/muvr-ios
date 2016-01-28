//
//  MRPebbleCommunication.h
//  Muvr
//
//  Created by Tom Bocklisch on 28.01.16.
//  Copyright © 2016 Muvr. All rights reserved.
//

#ifndef MRPebbleCommunication_h
#define MRPebbleCommunication_h

#include <stdio.h>

typedef struct __attribute__((__packed__)) {
    char name[24];
    uint8_t  confidence;       // 0..100
    uint8_t repetitions;       // 1..~50,  UNK_REPETITIONS for unknown
    uint8_t   intensity;       // 1..100,  UNK_INTENSITY for unknown
    uint16_t      weight;      // 1..~500, UNK_WEIGHT for unknown
} resistance_exercise_t;

void mk_resistance_exercise(void *memory, const char *name, const uint8_t confidence, const uint8_t repetitions, const uint8_t intensity, const uint16_t weight);



#endif /* MRPebbleCommunication_h */
