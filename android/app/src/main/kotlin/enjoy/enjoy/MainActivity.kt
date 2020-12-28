package enjoy.enjoy

import android.os.Bundle

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "enjoy/uidquery";

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "queryUid") {
                var pkg = call.arguments<String>()

                try{
                    var uid = this.getPackageManager().getApplicationInfo(pkg, 0).uid;
                    result.success(uid);
                }catch (e: Exception){
                    result.error("UIDERROR", "Get UID by package failed.", null)
                    println("Failed to get uid")
                }
            } else {
                result.notImplemented()
            }

        }
    }
}
