# By default give a warning and try to fix up packages.
USRMERGE_FIXUP ?= "fixup"

def usrmerge_relocate_files(pkgd, path):
    real_path = '/usr' + path
    link_path = path

    bb.warn('usrmerge: re{locat,link}ing %s to %s' % (link_path, real_path))

    # This naive approach fails if both path and '/usr' + path exist...
    os.renames(pkgd + link_path, pkgd + real_path)
    os.symlink(real_path.lstrip('/'), pkgd + link_path)

    cpath.updatecache(pkgd)


def usrmerge_relocate_meta(d, pkg):
    symlinks = [ '/bin', '/sbin', '/lib', '/lib64', '/lib32' ]
    files = d.getVar('FILES_' + pkg)

    relocated = []

    for f in (files or '').split():
        e = f
        for l in symlinks:
            if f == l or f.startswith(l + '/'):
                e = '/usr' + f
                break
        relocated.append(e)

    relocated_files = ' '.join(relocated)
    d.setVar('FILES_' + pkg, relocated_files)
    
    bb.warn('usrmerge: rewrote FILES_%s: to %s' % (pkg, relocated_files))


python populate_packages_append () {
    symlinks = [ '/bin', '/sbin', '/lib', '/lib64', '/lib32' ]

    recipe = d.getVar('FILE') or '<unknown recipe>'
    fixup = d.getVar('USRMERGE_FIXUP')

    pkgdest = d.getVar('PKGDEST')
    for pkg in (d.getVar('PACKAGES') or '').split():
        pkgd = os.path.join(pkgdest, pkg)

        for l in symlinks:
            if cpath.exists(pkgd + l) and not cpath.islink(pkgd + l):
                bb.warn(('usrmerge: package %s does not obey usrmerge\n' +
                         '    %s should be relocated under /usr') % (pkg, l))
                if fixup:
                    bb.warn('usrmerge: please fix recipe %s' % recipe)
                else:
                    bb.fatal('usrmerge: please fix recipe %s' % recipe)

                usrmerge_relocate_files(pkgd, l)
                usrmerge_relocate_meta(d, pkg)
}
