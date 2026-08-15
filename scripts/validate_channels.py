#!/usr/bin/env python3
"""channels.json 스키마 검증 (T-110/T-103 파이프라인)"""
import json, sys

def main():
    with open('anywhere_tv/assets/channels.json') as f:
        data = json.load(f)

    channels = data.get('channels', [])
    errors = []

    if not (30 <= len(channels) <= 50):
        errors.append(f'채널 수 30~50 위반: {len(channels)}')

    ids = [c.get('id') for c in channels]
    if len(set(ids)) != len(ids):
        errors.append('id 중복 존재')

    for c in channels:
        cid = c.get('id', '?')
        for field in ('id', 'name', 'category', 'sourceType', 'isDefaultFavorite'):
            if field not in c:
                errors.append(f'{cid}: {field} 누락')
        st = c.get('sourceType')
        if st == 'youtube_live':
            h, v = c.get('youtubeHandle'), c.get('youtubeVideoId')
            if not ((h and h.startswith('@')) or v):
                errors.append(f'{cid}: youtube 핸들/ID 잘못됨')
        elif st == 'hls':
            if not (c.get('streamUrl') or c.get('resolver')):
                errors.append(f'{cid}: streamUrl/resolver 누락')
        else:
            errors.append(f'{cid}: sourceType 오류 {st}')

    if errors:
        print('VALIDATION FAILED:')
        for e in errors:
            print(' -', e)
        sys.exit(1)
    print(f'OK: {len(channels)} channels, version={data.get("version")}')

if __name__ == '__main__':
    main()
