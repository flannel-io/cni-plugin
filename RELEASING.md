# Release process

## Resulting artifacts

### [Manual] Release using local artifacts
Creating a new release via `make release` produces the following directories containg artifacts:

- Binaries: 
  - `${GOPATH}/src/github.com/flannel-io/cni-plugin/dist`) 
    - `flannel-<ARCH>` binaries


- Tarfiles: 
  - `${GOPATH}/src/github.com/flannel-io/cni-plugin/release-"${TAG}"`
    - `cni-plugin-flannel-<OS>-<ARCH>-<TAG>.tar.gz` tarfiles containing one binary
    - `.sha1`, `.sha256`, and `.sha512` files for each tarfile.

### [Manual] Release using Docker artifacts
Creating a new release via `make release_docker` produces the following artifacts:

- Binaries (stored in the `release-<TAG>` directory) :
  - `flannel-<ARCH>-<VERSION>.tgz` binaries
  - `flannel-<ARCH>.tgz` binary (copy of amd64 platform binary)
  - `.sha1`, `.sha256`, and `.sha512` files for the above files.

## Preparing for a release
1. Releases are performed by maintainers and should usually be discussed and planned at a maintainer meeting.
  - Choose the version number. It should be prefixed with `v`, e.g. `v1.2.3`
  - Take a quick scan through the PRs and issues to make sure there isn't anything crucial that _must_ be in the next release.
  - Create a draft of the release note
  - Discuss the level of testing that's needed and create a test plan if sensible
  - Check what version of `go` is used in the build container, updating it if there's a new stable release.
  - Update the vendor directory and Godeps to pin to the corresponding containernetworking/cni release. Create a PR, makes sure it passes CI and get it merged.

## Creating the release artifacts
1. Make sure you are on the master branch and don't have any local uncommitted changes.
2. Create a signed tag for the release `git tag -s $VERSION` (Ensure that GPG keys are created and added to GitHub)
3. Run the release script from the root of the repository
  - `scripts/release.sh`
  - The script requires Docker and ensures that a consistent environment is used.
  - The artifacts will now be present in the `release-<TAG>` directory.
4. Test these binaries according to the test plan.

## Publishing the release
1. Push the tag to git `git push origin <TAG>`
2. Create a release on Github, using the tag which was just pushed.
3. Attach all the artifacts from the release directory.
4. Add the release note to the release.

