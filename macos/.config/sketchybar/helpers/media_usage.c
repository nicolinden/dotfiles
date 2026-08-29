#include <CoreAudio/CoreAudio.h>
#include <CoreMediaIO/CoreMediaIO.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

static bool audio_input_is_running(void) {
  AudioObjectPropertyAddress devices = {
      kAudioHardwarePropertyDevices,
      kAudioObjectPropertyScopeGlobal,
      kAudioObjectPropertyElementMain,
  };
  UInt32 size = 0;
  if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &devices, 0,
                                     NULL, &size) != noErr || size == 0) {
    return false;
  }

  AudioDeviceID *ids = malloc(size);
  if (ids == NULL) return false;
  if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &devices, 0, NULL,
                                 &size, ids) != noErr) {
    free(ids);
    return false;
  }

  bool active = false;
  UInt32 count = size / sizeof(AudioDeviceID);
  for (UInt32 index = 0; index < count && !active; index++) {
    AudioObjectPropertyAddress streams = {
        kAudioDevicePropertyStreams,
        kAudioDevicePropertyScopeInput,
        kAudioObjectPropertyElementMain,
    };
    UInt32 stream_size = 0;
    if (AudioObjectGetPropertyDataSize(ids[index], &streams, 0, NULL,
                                       &stream_size) != noErr ||
        stream_size == 0) {
      continue;
    }

    AudioObjectPropertyAddress running = {
        kAudioDevicePropertyDeviceIsRunningSomewhere,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain,
    };
    UInt32 value = 0;
    UInt32 value_size = sizeof(value);
    if (AudioObjectGetPropertyData(ids[index], &running, 0, NULL, &value_size,
                                   &value) == noErr && value != 0) {
      active = true;
    }
  }
  free(ids);
  return active;
}

static bool camera_is_running(void) {
  CMIOObjectPropertyAddress devices = {
      kCMIOHardwarePropertyDevices,
      kCMIOObjectPropertyScopeGlobal,
      kCMIOObjectPropertyElementMain,
  };
  UInt32 size = 0;
  if (CMIOObjectGetPropertyDataSize(kCMIOObjectSystemObject, &devices, 0, NULL,
                                    &size) != noErr || size == 0) {
    return false;
  }

  CMIODeviceID *ids = malloc(size);
  if (ids == NULL) return false;
  UInt32 used = 0;
  if (CMIOObjectGetPropertyData(kCMIOObjectSystemObject, &devices, 0, NULL,
                                size, &used, ids) != noErr) {
    free(ids);
    return false;
  }

  bool active = false;
  UInt32 count = size / sizeof(CMIODeviceID);
  CMIOObjectPropertyAddress running = {
      kCMIODevicePropertyDeviceIsRunningSomewhere,
      kCMIOObjectPropertyScopeGlobal,
      kCMIOObjectPropertyElementMain,
  };
  for (UInt32 index = 0; index < count && !active; index++) {
    UInt32 value = 0;
    UInt32 value_size = sizeof(value);
    UInt32 value_used = 0;
    if (CMIOObjectGetPropertyData(ids[index], &running, 0, NULL, value_size,
                                  &value_used, &value) == noErr && value != 0) {
      active = true;
    }
  }
  free(ids);
  return active;
}

int main(void) {
  printf("mic=%d camera=%d\n", audio_input_is_running() ? 1 : 0,
         camera_is_running() ? 1 : 0);
  return 0;
}
