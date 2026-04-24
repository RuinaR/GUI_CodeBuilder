// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'document_store.dart';

DocumentStore createDefaultDocumentStore() {
  return const WebDownloadDocumentStore();
}

class WebDownloadDocumentStore implements DocumentStore {
  const WebDownloadDocumentStore();

  @override
  Future<void> saveExportBundle(DocumentExportBundle bundle) async {
    for (final entry in bundle.flattenedFiles().entries) {
      _downloadTextFile(_downloadName(entry.key), entry.value);
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  @override
  Future<String?> readText(String relativePath) async {
    return null;
  }

  void _downloadTextFile(String fileName, String text) {
    final blob = html.Blob(<String>[text], 'text/plain;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  String _downloadName(String relativePath) {
    return 'exports_${relativePath.replaceAll('/', '_')}';
  }
}
