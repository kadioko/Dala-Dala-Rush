package com.kadioko.dalaconsent;

import android.app.Activity;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.Collections;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;

/** Thin UMP bridge. SDK consent state, never a saved game preference, controls ads. */
public final class DalaConsent extends GodotPlugin {
    private final AtomicBoolean busy = new AtomicBoolean(false);
    private volatile boolean allowed;
    private volatile boolean optionsRequired;

    public DalaConsent(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "DalaConsent"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return Collections.singleton(new SignalInfo("consent_updated", Boolean.class, Boolean.class, String.class));
    }
    @UsedByGodot public boolean canRequestAds() { return allowed; }
    @UsedByGodot public boolean privacyOptionsRequired() { return optionsRequired; }

    @UsedByGodot public void requestConsent() {
        Activity activity = getActivity();
        if (activity == null || !busy.compareAndSet(false, true)) return;
        activity.runOnUiThread(() -> {
            ConsentInformation info = UserMessagingPlatform.getConsentInformation(activity);
            info.requestConsentInfoUpdate(activity, new ConsentRequestParameters.Builder().build(),
                () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity,
                    error -> publish(info, error)), error -> publish(info, error));
        });
    }

    @UsedByGodot public void showPrivacyOptions() {
        Activity activity = getActivity();
        if (activity == null || !busy.compareAndSet(false, true)) return;
        activity.runOnUiThread(() -> UserMessagingPlatform.showPrivacyOptionsForm(activity,
            error -> publish(UserMessagingPlatform.getConsentInformation(activity), error)));
    }

    private void publish(ConsentInformation info, FormError error) {
        allowed = info.canRequestAds();
        optionsRequired = info.getPrivacyOptionsRequirementStatus()
            == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
        busy.set(false);
        emitSignal("consent_updated", allowed, optionsRequired,
            error == null ? "" : Integer.toString(error.getErrorCode()));
    }
}
