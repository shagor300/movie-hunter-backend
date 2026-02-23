/// Movie tag models for quality and audio classification.
library;

/// Tags are auto-parsed from movie titles and download link names.
class MovieTags {
  /// Extract quality tags from a text string (title or link name).
  static Set<QualityTag> parseQualityTags(String text) {
    final tags = <QualityTag>{};
    final lower = text.toLowerCase();

    if (lower.contains('4k') || lower.contains('2160p')) {
      tags.add(QualityTag.uhd4k);
    }
    if (lower.contains('1080p') || lower.contains('full hd')) {
      tags.add(QualityTag.fullHD);
    }
    if (lower.contains('720p') || lower.contains('hd ')) {
      tags.add(QualityTag.hd720);
    }
    if (lower.contains('480p')) {
      tags.add(QualityTag.sd480);
    }
    if (lower.contains('hevc') ||
        lower.contains('x265') ||
        lower.contains('h265')) {
      tags.add(QualityTag.hevc);
    }
    if (lower.contains('x264') || lower.contains('h264')) {
      tags.add(QualityTag.h264);
    }
    if (lower.contains('bluray') || lower.contains('blu-ray')) {
      tags.add(QualityTag.bluRay);
    }
    if (lower.contains('web-dl') ||
        lower.contains('webdl') ||
        lower.contains('webrip')) {
      tags.add(QualityTag.webDL);
    }
    if (lower.contains('hdr') || lower.contains('hdr10')) {
      tags.add(QualityTag.hdr);
    }
    if (lower.contains('cam') || lower.contains('hdcam')) {
      tags.add(QualityTag.cam);
    }

    return tags;
  }

  /// Extract audio tags from a text string.
  static Set<AudioTag> parseAudioTags(String text) {
    final tags = <AudioTag>{};
    final lower = text.toLowerCase();

    if (lower.contains('dual audio')) {
      tags.add(AudioTag.dualAudio);
    }
    if (lower.contains('hindi dub') || lower.contains('hindi dubbed')) {
      tags.add(AudioTag.hindiDubbed);
    }
    if (lower.contains('english')) {
      tags.add(AudioTag.english);
    }
    if (lower.contains('bengali') || lower.contains('bangla')) {
      tags.add(AudioTag.bengali);
    }
    if (lower.contains('multi audio')) {
      tags.add(AudioTag.multiAudio);
    }
    if (lower.contains('esub') || lower.contains('eng sub')) {
      tags.add(AudioTag.engSub);
    }
    if (lower.contains('aac')) {
      tags.add(AudioTag.aac);
    }
    if (lower.contains('atmos') || lower.contains('dolby')) {
      tags.add(AudioTag.atmos);
    }

    return tags;
  }
}

enum QualityTag {
  uhd4k('4K', '🔥'),
  fullHD('1080p', '✨'),
  hd720('720p', '📺'),
  sd480('480p', '📱'),
  hevc('HEVC', '⚡'),
  h264('H.264', '🎞️'),
  bluRay('BluRay', '💿'),
  webDL('WEB-DL', '🌐'),
  hdr('HDR', '🌈'),
  cam('CAM', '📹');

  final String label;
  final String emoji;
  const QualityTag(this.label, this.emoji);
}

enum AudioTag {
  dualAudio('Dual Audio', '🎧'),
  hindiDubbed('Hindi Dubbed', '🇮🇳'),
  english('English', '🇬🇧'),
  bengali('Bengali', '🇧🇩'),
  multiAudio('Multi Audio', '🎵'),
  engSub('Eng Sub', '📝'),
  aac('AAC', '🔊'),
  atmos('Atmos', '🎶');

  final String label;
  final String emoji;
  const AudioTag(this.label, this.emoji);
}
