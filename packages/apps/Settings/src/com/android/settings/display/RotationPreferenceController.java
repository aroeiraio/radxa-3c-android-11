/*
 * Copyright (C) 2023 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.android.settings.display;

import static android.provider.Settings.System.USER_ROTATION;

import android.content.Context;
import android.provider.Settings;
import android.util.Log;

import androidx.preference.ListPreference;
import androidx.preference.Preference;

import com.android.settings.core.PreferenceControllerMixin;
import com.android.settingslib.core.AbstractPreferenceController;

public class RotationPreferenceController extends AbstractPreferenceController implements
        PreferenceControllerMixin, Preference.OnPreferenceChangeListener {

    private static final String TAG = "RotationPrefController";
    private static final int DEFAULT_ROTATION_VALUE = 0;

    private final String mRotationKey;

    public RotationPreferenceController(Context context, String key) {
        super(context);
        mRotationKey = key;
    }

    @Override
    public boolean isAvailable() {
        return true;
    }

    @Override
    public String getPreferenceKey() {
        return mRotationKey;
    }

    @Override
    public void updateState(Preference preference) {
        final ListPreference rotationPreference = (ListPreference) preference;
        int currentRotation = Settings.System.getInt(mContext.getContentResolver(),
                USER_ROTATION, DEFAULT_ROTATION_VALUE);

        Log.d(TAG, "Current USER_ROTATION value: " + currentRotation);
        rotationPreference.setValue(String.valueOf(currentRotation));
        updateRotationPreferenceDescription(rotationPreference, currentRotation);
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        try {
            int rotation = Integer.parseInt((String) newValue);
            Log.d(TAG, "Setting USER_ROTATION to: " + rotation);

            Settings.System.putInt(mContext.getContentResolver(), USER_ROTATION, rotation);
            updateRotationPreferenceDescription((ListPreference) preference, rotation);
            return true;
        } catch (NumberFormatException e) {
            Log.e(TAG, "Could not persist rotation setting", e);
            return false;
        }
    }

    private void updateRotationPreferenceDescription(ListPreference preference, int currentRotation) {
        final CharSequence[] entries = preference.getEntries();
        final CharSequence[] values = preference.getEntryValues();

        String summary = "";
        if (entries != null && values != null) {
            for (int i = 0; i < values.length; i++) {
                try {
                    int rotationValue = Integer.parseInt(values[i].toString());
                    if (currentRotation == rotationValue) {
                        summary = entries[i].toString();
                        break;
                    }
                } catch (NumberFormatException e) {
                    Log.w(TAG, "Invalid rotation value: " + values[i]);
                }
            }
        }

        Log.d(TAG, "Setting rotation preference summary to: " + summary);
        preference.setSummary(summary);
    }
}