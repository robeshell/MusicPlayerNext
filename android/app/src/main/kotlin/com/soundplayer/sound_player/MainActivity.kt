package com.soundplayer.sound_player

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val channelName =
            "com.soundplayer.sound_player/local_directory_access"
        private const val pickDirectoryRequestCode = 9401
    }

    private var pendingDirectoryResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler(::handleDirectoryMethod)
    }

    private fun handleDirectoryMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectory" -> pickDirectory(result)
            "restoreDirectory" -> restoreDirectory(call, result)
            "releaseDirectory" -> releaseDirectory(call, result)
            else -> result.notImplemented()
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        if (pendingDirectoryResult != null) {
            result.error(
                "directory_picker_active",
                "A directory picker is already active.",
                null,
            )
            return
        }
        pendingDirectoryResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        startActivityForResult(intent, pickDirectoryRequestCode)
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickDirectoryRequestCode) return
        val result = pendingDirectoryResult ?: return
        pendingDirectoryResult = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }

        val takeFlags = data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
        try {
            contentResolver.takePersistableUriPermission(uri, takeFlags)
            result.success(grant(uri, "available"))
        } catch (_: SecurityException) {
            result.success(grant(uri, "permissionRequired"))
        } catch (_: IllegalArgumentException) {
            // Providers may reject persistence even after returning a tree URI.
            result.success(grant(uri, "permissionRequired"))
        }
    }

    private fun restoreDirectory(call: MethodCall, result: MethodChannel.Result) {
        val rootUri = call.argument<String>("rootUri")
        if (rootUri == null) {
            result.error("invalid_directory_grant", "A root URI is required.", null)
            return
        }
        val uri = Uri.parse(rootUri)
        val permission = contentResolver.persistedUriPermissions.firstOrNull {
            it.uri == uri && it.isReadPermission
        }
        if (permission == null) {
            result.success(grant(uri, "permissionRequired"))
            return
        }

        val status = try {
            contentResolver.query(
                documentUri(uri),
                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) "available" else "unavailable"
            } ?: "unavailable"
        } catch (_: SecurityException) {
            "permissionRequired"
        } catch (_: Exception) {
            "unavailable"
        }
        result.success(grant(uri, status))
    }

    private fun releaseDirectory(call: MethodCall, result: MethodChannel.Result) {
        val rootUri = call.argument<String>("rootUri")
        if (rootUri != null) {
            try {
                contentResolver.releasePersistableUriPermission(
                    Uri.parse(rootUri),
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            } catch (_: SecurityException) {
                // The permission was already revoked by the user or provider.
            }
        }
        result.success(null)
    }

    private fun grant(uri: Uri, status: String): Map<String, Any?> {
        return mapOf(
            "rootUri" to uri.toString(),
            "displayName" to displayName(uri),
            "status" to status,
            "permissionToken" to null,
            "isStale" to false,
        )
    }

    private fun displayName(treeUri: Uri): String {
        return try {
            contentResolver.query(
                documentUri(treeUri),
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            } ?: DocumentsContract.getTreeDocumentId(treeUri)
        } catch (_: Exception) {
            treeUri.lastPathSegment ?: treeUri.toString()
        }
    }

    private fun documentUri(treeUri: Uri): Uri {
        return DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
    }
}
