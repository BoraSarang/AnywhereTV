#!/usr/bin/env python3
"""리졸버 헬스체크: KBS landing API + 정적 HLS 스트림 + 유튜브 라이브 채널 확인 (T-103)"""
import json, sys, urllib.request, ssl

def get(url, timeout=10):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 AnywhereTVHealthCheck/1.0'})
    return urllib.request.urlopen(req, timeout=timeout)

def main():
    failures = []
    checks = 0

    # 1. KBS landing API (지상파 채널)
    for code, name in [('11', 'KBS1'), ('12', 'KBS2'), ('21', 'KBS 1라디오')]:
        checks += 1
        try:
            with get(f'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/{code}') as r:
                body = json.loads(r.read())
            items = body.get('channel_item') or []
            if items and items[0].get('service_url'):
                print(f'OK KBS {name} (code {code})')
            else:
                failures.append(f'KBS {name}: service_url 없음')
        except Exception as e:
            failures.append(f'KBS {name}: {e}')

    # 2. 정적 라디오 HLS 스트림
    streams = [
        ('TBN 경인', 'http://radio2.tbn.or.kr:1935/gyeongin/myStream/playlist.m3u8'),
        ('FEBC 서울', 'http://mlive2.febc.net:1935/live/seoulfm/playlist.m3u8'),
        ('EBS FM', 'https://ebsonair.ebs.co.kr/fmradiofamilypc/familypc1m/playlist.m3u8'),
        ('YTN 라디오', 'https://radiolive.ytn.co.kr/radio/_definst_/20211118_fmlive/playlist.m3u8'),
    ]
    for name, url in streams:
        checks += 1
        try:
            with get(url) as r:
                if r.status == 200 and r.read(1000).startswith(b'#EXTM3U'):
                    print(f'OK {name} HLS')
                else:
                    failures.append(f'{name}: 비정상 응답')
        except Exception as e:
            failures.append(f'{name}: {e}')

    # 3. 유튜브 라이브 채널 (24시간 뉴스/종편)
    handles = ['@KBSNEWS', '@JTBC', '@TVCHOSUN', '@channela', '@ktv', '@natv']
    for h in handles:
        checks += 1
        try:
            with get(f'https://www.youtube.com/{h}/live') as r:
                if r.status == 200:
                    print(f'OK 유튜브 {h}')
                else:
                    failures.append(f'유튜브 {h}: HTTP {r.status}')
        except Exception as e:
            failures.append(f'유튜브 {h}: {e}')

    print(f'\n{checks} checks, {len(failures)} failures')
    if failures:
        for f in failures:
            print(' FAIL:', f)
        sys.exit(1)

if __name__ == '__main__':
    main()
