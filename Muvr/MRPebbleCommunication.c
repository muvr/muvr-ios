//
//  MRPebbleCommunication.c
//  Muvr
//
//  Created by Tom Bocklisch on 28.01.16.
//  Copyright © 2016 Muvr. All rights reserved.
//

#include <stdio.h>
#include "MRPebbleCommunication.h"

void mk_resistance_exercise(void *memory, const char *name, const uint8_t confidence, const uint8_t repetitions, const uint8_t intensity, const uint16_t weight) {
    resistance_exercise_t *re = (resistance_exercise_t*)memory;
    strncpy(re->name, name, 24);
    re->confidence = confidence;
    re->repetitions = repetitions;
    re->intensity = intensity;
    re->weight = weight;
}