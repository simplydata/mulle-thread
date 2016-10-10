#! /bin/sh

NAME="mulle-thread"  # not the ruby name
HEADER="src/mulle_thread.h"
VERSIONNAME="MULLE_THREAD_VERSION"
ORIGIN=public

RBFILE="${NAME}.rb"
HOMEBREWTAP="../homebrew-software"


get_version()
{
   local filename

   filename="$1"
   fgrep "${VERSIONNAME}" "${filename}" | \
   sed 's|(\([0-9]*\) \<\< [0-9]*)|\1|g' | \
   sed 's|^.*(\(.*\))|\1|' | \
   sed 's/ | /./g'
}

VERSION="`get_version ${HEADER}`"
TAG="${1:-${VERSION}}"


directory="`mulle-bootstrap library-path 2> /dev/null`"
[ ! -d "${directory}" ] && echo "failed to locate mulle-bootstrap library" >&2 && exit 1

PATH="${directory}:$PATH"

. "mulle-bootstrap-logging.sh"


git_must_be_clean()
{
   local name
   local clean

   name="${1:-${PWD}}"

   if [ ! -d .git ]
   then
      fail "\"${name}\" is not a git repository"
   fi

   clean=`git status -s --untracked-files=no`
   if [ "${clean}" != "" ]
   then
      fail "repository \"${name}\" is tainted"
   fi
}


[ ! -d "${HOMEBREWTAP}" ] && fail "failed to locate \"${HOMEBREWTAP}\""

set -e

git_must_be_clean

branch="`git rev-parse --abbrev-ref HEAD`"

git push "${ORIGIN}" "${branch}"

# seperate step, as it's tedious to remove tag when
# previous push fails

git tag "${TAG}"
git push "${ORIGIN}" "${branch}" --tags

./bin/generate-brew-formula.sh "${VERSION}" > "${HOMEBREWTAP}/${RBFILE}"
(
   cd "${HOMEBREWTAP}" ;
   git add "${RBFILE}" ;
   git commit -m "${TAG} release of ${NAME}" "${RBFILE}" ;
   git push origin master
)

git checkout "${branch}"
