Docker image for recording from Radiko.
===========================================
Radiko.jpよりmp3形式で録音するためのDockerコンテナです。  
cron等に仕込んでお使い下さい。

スクリプトは、[matchy2さんの公開している成果](https://gist.github.com/matchy2/3956266)を流用させて頂きつつ、MP3タグを打つオプションなどのアレンジを加えました。感謝！

Usage
--------------
    docker run --rm -v path/to/output/dir:/data sarlos/rec-radiko channel_name duration(minuites) [prefix] [album artist]

