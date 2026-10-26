#!/usr/bin/env python3
"""Offline workflow checks with mocked source sync, build and upload."""
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap

ROOT = Path(__file__).resolve().parents[1]
PIXELDRAIN_AUTH = re.search(r'curl[^\n]+ -u ([^\s]+)', (ROOT/'script.sh').read_text()).group(1)


def write(path, content, executable=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(content).lstrip())
    if executable:
        path.chmod(0o755)


with tempfile.TemporaryDirectory(prefix='lineage23-builder-test-') as directory:
    tmp = Path(directory)
    mockbin = tmp / 'bin'
    mockbin.mkdir()
    write(mockbin/'git', '''#!/usr/bin/env python3
import os,pathlib,sys,json
args=sys.argv[1:]
with open(os.environ['CALL_LOG'],'a') as f:f.write(json.dumps(['git',*args])+'\\n')
if args[0]=='clone':
    branch_arg = '--branch' if '--branch' in args else '-b'
    assert args[args.index(branch_arg)+1]=='lineage-23.2'
    assert 'https://github.com/Kyura-Ground/local_manifests.git' in args
    pathlib.Path(args[-1]).mkdir(parents=True)
''', True)
    write(mockbin/'repo', '''#!/usr/bin/env python3
import os,pathlib,sys,json,shutil
args=sys.argv[1:]
with open(os.environ['CALL_LOG'],'a') as f:f.write(json.dumps(['repo',*args])+'\\n')
if args[0]=='init':
    assert args[args.index('-b')+1]=='lineage-23.2'
    assert args[args.index('-u')+1]=='https://github.com/LineageOS/android.git'
    sys.exit(0)
assert args[0]=='sync'
if os.environ.get('SYNC_FAIL')=='1':sys.exit(17)
for rel in ['device/asus/X00TD/lineage_X00TD.mk',
            'device/asus/sdm660-common/BoardConfigCommon.mk',
            'vendor/asus/X00TD/X00TD-vendor.mk',
            'vendor/asus/sdm660-common/sdm660-common-vendor.mk',
            'kernel/asus/sdm660/drivers/Makefile','kernel/asus/sdm660/drivers/Kconfig',
            'kernel/asus/sdm660/arch/arm64/configs/X00TD_defconfig']:
    p=pathlib.Path(rel);p.parent.mkdir(parents=True,exist_ok=True);p.write_text('# fixture\\n')
p=pathlib.Path('kernel/asus/sdm660/Makefile')
p.write_text('VERSION = 4\\nPATCHLEVEL = '+('19' if os.environ.get('WRONG_KERNEL') else '4')+'\\n')
p=pathlib.Path('build/envsetup.sh');p.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(os.environ['ENV_FIXTURE'],p)
''', True)
    write(mockbin/'curl', """#!/usr/bin/env python3
import json,os,sys,pathlib
args=sys.argv[1:]
if any('/kernel/setup.sh' in arg for arg in args):
    assert args[-1]=='https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh'
    if os.environ.get('KSU_SETUP_FAIL')=='1':sys.exit(22)
    print('test "$1" = master || exit 1')
    print('mkdir -p KernelSU/kernel')
    print('printf "config KSU\\n" > KernelSU/kernel/Kconfig')
    print('ln -s ../KernelSU/kernel drivers/kernelsu')
    sys.exit(0)
assert '-T' in args
path=pathlib.Path(args[args.index('-T')+1])
assert path.name.startswith('lineage-23.2-') and path.suffix=='.zip'
assert args[args.index('-u')+1]==os.environ['EXPECTED_PIX_AUTH']
with open(os.environ['CALL_LOG'],'a') as f:f.write(json.dumps(['upload',path.name])+'\\n')
if os.environ.get('UPLOAD_FAIL')=='1' or path.stat().st_size==0:sys.exit(22)
print('{"success":true}')
""", True)
    write(mockbin/'make', '''#!/usr/bin/env python3
import os,sys
assert sys.argv[1:]==['installclean']
with open(os.environ['EVENT_LOG'],'a') as f:f.write('installclean\\n')
''', True)
    write(tmp/'envsetup.sh', '''
        # An optional Android probe must not terminate sourcing.
        false
        lunch() {
            [[ "$#" == 1 && "$1" == lineage_X00TD-bp4a-userdebug ]] || return 41
            [[ -z "${WITH_GAPPS+x}" ]] || return 42
            [[ "${LUNCH_FAIL:-0}" != 1 ]] || return 19
            printf 'lunch\\n' >> "$EVENT_LOG"
        }
        breakfast() {
            [[ "$*" == "X00TD userdebug" ]] || return 43
            lunch lineage_X00TD-bp4a-userdebug
        }
        m() {
            [[ "${WITH_GMS:-}" == false && -z "${TARGET_GAPPS_VARIANT+x}" ]] || return 45
            [[ "${BUILD_USERNAME:-}" == kyura && "${BUILD_HOSTNAME:-}" == crave ]] || return 46
            local target="${!#}"
            printf '%s\\n' "$target" >> "$EVENT_LOG"
            if [[ "$target" == installclean ]]; then
                [[ "$*" == installclean ]] || return 44
                [[ "${CLEAN_FAIL:-0}" != 1 ]] || return 31
                return 0
            fi
            [[ "$*" == "-j${BUILD_JOBS:-32} bacon" ]] || return 44
            [[ "${BUILD_FAIL:-0}" != 1 ]] || return 23
            mkdir -p out/target/product/X00TD
            [[ "${NO_ARTIFACT:-0}" != 1 ]] || return 0
            if [[ "${EMPTY_ARTIFACT:-0}" == 1 ]]; then
                : > out/target/product/X00TD/lineage-23.2-new-UNOFFICIAL-X00TD.zip
            else
                printf 'fixture zip\\n' > out/target/product/X00TD/lineage-23.2-new-UNOFFICIAL-X00TD.zip
            fi
            if [[ "${EXTRA_LINEAGE_ZIP:-0}" == 1 ]]; then
                printf 'another zip\\n' > out/target/product/X00TD/lineage-23.2-custom-X00TD.zip
                printf 'other ROM\\n' > out/target/product/X00TD/Project_Infinity-X.zip
            fi
        }
        [[ "${ENV_FAIL:-0}" != 1 ]] || return 7
        return 0
    ''')

    def run(name, overrides=None, expected_status=0, expected_error=None):
        work = tmp/name
        (work/'.repo').mkdir(parents=True)
        keys = work/'vendor/lineage-priv/keys'
        keys.mkdir(parents=True)
        write(keys/'keys.mk', '# keep this identity\n')
        write(keys/'releasekey.pk8', 'existing key fixture\n')
        write(keys/'releasekey.x509.pem', 'existing certificate fixture\n')
        original = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in keys.iterdir()}
        write(work/'vendor/asus/other/keep.txt', 'unrelated vendor tree\n')
        markers = [work/'vendor/asus'/name/'checkout-marker' for name in ('X00TD', 'sdm660-common')]
        for marker in markers:
            write(marker, 'existing vendor checkout\n')
        if name == 'combined-vendor-checkout':
            (work/'vendor/asus/.git').mkdir()
        out = work/'out/target/product/X00TD'
        out.mkdir(parents=True)
        stale = work/'lineage-23.2-old-UNOFFICIAL-X00TD.zip'
        stale.write_bytes(b'old zip')
        if name == 'stale-artifact':
            old_package = out/'lineage-23.2-stale-UNOFFICIAL-X00TD.zip'
            old_package.write_bytes(b'old output zip')
            os.utime(old_package, (1, 1))
        os.utime(stale, (1, 1))
        env = dict(PATH=str(mockbin)+os.pathsep+os.environ['PATH'],
                   HOME=os.environ['HOME'],
                   ENV_FIXTURE=str(tmp/'envsetup.sh'), CALL_LOG=str(work/'calls.jsonl'),
                   EVENT_LOG=str(work/'events.log'), WITH_GAPPS='true',
                   WITH_GMS='true', TARGET_GAPPS_VARIANT='full',
                   EXPECTED_PIX_AUTH=PIXELDRAIN_AUTH)
        env.update(overrides or {})
        result = subprocess.run(['bash', str(ROOT/'script.sh')], cwd=work, env=env,
                                text=True, capture_output=True)
        assert result.returncode == expected_status, (name, result.returncode, result.stdout, result.stderr)
        if expected_error:
            assert expected_error in result.stdout+result.stderr, name
        assert {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in keys.iterdir()} == original
        assert (work/'vendor/asus/other/keep.txt').read_text() == 'unrelated vendor tree\n'
        assert all(marker.exists() == (name == 'combined-vendor-checkout') for marker in markers)
        assert not list(work.glob('.lineage-build-start.*')), name
        calls = [json.loads(line) for line in (work/'calls.jsonl').read_text().splitlines()]
        uploads = [call[1] for call in calls if call[0]=='upload']
        assert bool(uploads) == (expected_status == 0 or name in ['upload-failure','empty-artifact']), name
        assert stale.name not in uploads
        if name in ['upload-failure','empty-artifact']:
            assert (out/'lineage-23.2-new-UNOFFICIAL-X00TD.zip').is_file()
        if expected_status == 0:
            assert (work/'events.log').read_text().splitlines() == ['lunch', 'installclean', 'bacon']
            kernel = work/'kernel/asus/sdm660'
            assert (kernel/'drivers/kernelsu').resolve() == kernel/'KernelSU/kernel'
            assert (kernel/'arch/arm64/configs/X00TD_defconfig').read_text() == '# fixture\n'
            assert (work/'lineage-23.2-new-UNOFFICIAL-X00TD.zip').is_file()
            assert not list(out.glob('lineage-23.2-*-X00TD.zip'))
            if env.get('EXTRA_LINEAGE_ZIP') == '1':
                assert len(uploads) == 2 and 'lineage-23.2-custom-X00TD.zip' in uploads
                assert (work/'lineage-23.2-custom-X00TD.zip').is_file()
                assert (out/'Project_Infinity-X.zip').is_file()
        print(name+': PASS')

    run('ksu')
    run('combined-vendor-checkout')
    run('jobs-192', {'BUILD_JOBS': '192'})
    run('lineage-wildcard', {'EXTRA_LINEAGE_ZIP': '1'})
    run('sync-failure', {'SYNC_FAIL': '1'}, 17)
    run('ksu-setup-failure', {'KSU_SETUP_FAIL': '1'}, 22)
    run('env-failure', {'ENV_FAIL': '1'}, 7, 'Environment setup failed')
    run('lunch-failure', {'LUNCH_FAIL': '1'}, 19)
    run('wrong-kernel', {'WRONG_KERNEL': '1'}, 1, 'Expected Linux 4.4')
    run('installclean-failure', {'CLEAN_FAIL': '1'}, 31)
    run('stale-artifact', {'NO_ARTIFACT': '1'}, 1, 'No new LineageOS 23.2 package')
    run('build-failure', {'BUILD_FAIL': '1'}, 23)
    run('no-artifact', {'NO_ARTIFACT': '1'}, 1, 'File tidak ditemukan!')
    run('empty-artifact', {'EMPTY_ARTIFACT': '1'}, 22)
    run('upload-failure', {'UPLOAD_FAIL': '1'}, 22)
