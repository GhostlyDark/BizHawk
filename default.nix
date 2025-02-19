# THIS IS A WORK IN PROGRESS!
# To save you having to build Mono locally, install the Cachix client (`nix-env -iA nixpkgs.cachix`) and run `cachix use mono-for-bizhawk` (both commands only need to run once ever). See https://docs.cachix.org for more info.

{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/21.11.tar.gz") {}
# infrastructure
, stdenv ? pkgs.stdenvNoCC
, buildDotnetModule ? pkgs.buildDotnetModule
, fetchFromGitHub ? pkgs.fetchFromGitHub
#, makeDesktopItem ? pkgs.makeDesktopItem
, makeWrapper ? pkgs.makeWrapper
# source
, useCWDAsSource ? false
, hawkSourceInfo ? if useCWDAsSource
	then rec {
		version = "2.7.1-local"; # distinguishes parallel installs' config and other data
		shorthash = "000000000"; # this and the branch name are written into movies and savestates, written to config to detect in-place upgrades (N/A to Nix), and of course also shown in the About dialog
		branch = "master"; # must be regex-escaped (interpolated as `sed "s/.../${branch}/"`)
		drv = builtins.path {
			path = ./.;
			name = "BizHawk-${version}";
			filter = let # this is just for speed, not any r13y concern
				denyList = [ ".git" ".idea" "ExternalCoreProjects" "ExternalProjects" "ExternalToolProjects" "libHawk" "libmupen64plus" "LibretroBridge" "LuaInterface" "lynx" "psx" "quicknes" "submodules" "waterbox" "wonderswan" ];
			in path: type: type == "regular" || (type == "directory" && !builtins.elem (baseNameOf path) denyList);
		};
	}
	else {
		version = "2.7";
		shorthash = "dbaf25956";
		branch = "master";
		drv = fetchFromGitHub {
			owner = "TASEmulators";
			repo = "BizHawk";
			rev = "dbaf2595625f79093eeec37d2d4a7a9a4d37f370";
			hash = "sha256-KXe69svPIIFaXgT9t+02pwdQ6WWqdqgUdtaE2S4/YxA=";
		};
	}
# makedeps
, dotnet-sdk_5 ? pkgs.dotnetCorePackages.sdk_5_0
, dotnet-sdk_6 ? pkgs.dotnetCorePackages.sdk_6_0
, p7zip ? pkgs.p7zip
# rundeps for NixOS hosts
#, gtk2-x11 ? pkgs.gtk2-x11
# rundeps for all Linux hosts
, mesa ? pkgs.mesa
, mono ? null
, openal ? pkgs.openal
, uname ? stdenv
# other parameters
, buildConfig ? "Release" # "Debug"/"Release"
, debugPInvokes ? false # forwarded to Dist/wrapper-scripts.nix
, doCheck ? false # runs `Dist/BuildTest${buildConfig}.sh`
, forNixOS ? false
, initConfig ? {} # forwarded to Dist/wrapper-scripts.nix (see docs there)
}:
let
	lib = pkgs.lib;
	commentUnless = b: lib.optionalString (!b) "# ";
	versionAtLeast = exVer: acVer: builtins.compareVersions exVer acVer <= 0;
	monoFinal = if mono != null
		then mono
		else if versionAtLeast "6.12.0.151" pkgs.mono.version
			then pkgs.mono
			else pkgs.callPackage Dist/mono-6.12.0.151.nix {}; # not actually reproducible :( https://github.com/NixOS/nixpkgs/issues/143110#issuecomment-984251253
	bizhawk = buildDotnetModule rec {
		pname = "BizHawk";
		version = hawkSourceInfo.version;
		src = hawkSourceInfo.drv;
		outputs = [ "bin" "out" ];
		dotnet-sdk = if useCWDAsSource then dotnet-sdk_6 else dotnet-sdk_5;
		nativeBuildInputs = [ p7zip ];
		buildInputs = [ mesa monoFinal openal uname ];# ++ lib.optionals (forNixOS) [ gtk2-x11 ];
		projectFile = "BizHawk.sln";
		nugetDeps = if useCWDAsSource then Dist/deps.nix else Dist/deps-old.nix;
		extraDotnetBuildFlags = "-maxcpucount:$NIX_BUILD_CORES -p:BuildInParallel=true --no-restore";
		postPatch = ''
			# confused? '$(...)' is literal here
			# these scripts invoke Git in subshells and we want to run them now, at compile time, without Git
			sed -i 's/$(git rev-parse --verify HEAD)/${hawkSourceInfo.shorthash}/' Dist/.InvokeCLIOnMainSln.sh
			sed -i -e 's/$(git rev-parse --abbrev-ref HEAD)/${hawkSourceInfo.branch}/' -e 's/$(git log -1 --format="%h")/${hawkSourceInfo.shorthash}/' Build/standin.sh
			sed -i 's/$(git rev-list HEAD --count)//' Build/standin.sh # const field is unused

			# stop MSBuild from copying Assets, we'll do that later
			sed -i '/Assets\/\*\*/d' src/BizHawk.Client.EmuHawk/BizHawk.Client.EmuHawk.csproj
			sed -i '/mkdir "packaged_output\/Firmware/d' Dist/Package.sh # and we don't need this
		'';
		buildPhase = ''
			${commentUnless useCWDAsSource}cd src/BizHawk.Version
			${commentUnless useCWDAsSource}dotnet build ${extraDotnetBuildFlags}
			${commentUnless useCWDAsSource}cd ../..
			Dist/Build${buildConfig}.sh ${extraDotnetBuildFlags}
			printf "NixHawk" >output/dll/custombuild.txt
			Dist/Package.sh linux-x64
		'';
		inherit doCheck;
		checkPhase = ''
			export GITLAB_CI=1 # pretend to be in GitLab CI -- platform-specific tests don't run in CI because they assume an Arch filesystem (on Linux hosts)
			# from 2.7.1, use standard -p:ContinuousIntegrationBuild=true instead
			Dist/BuildTest${buildConfig}.sh ${extraDotnetBuildFlags}

			# can't build w/ extra Analyzers, it fails to restore :(
#			Dist/Build${buildConfig}.sh -p:MachineRunAnalyzersDuringBuild=true ${extraDotnetBuildFlags}
		'';
		installPhase = ''
			cp -avT packaged_output $bin
			cp -avt $bin Assets/defctrl.json && rm Assets/defctrl.json
			cp -avt $bin/dll Assets/dll/* && rm -r Assets/dll
			rm Assets/EmuHawkMono.sh # replaced w/ scripts from wrapperScripts
			cp -avt $bin Assets/gamedb && rm -r Assets/gamedb
			cp -avt $bin Assets/Shaders && rm -r Assets/Shaders
			cp -avT Assets $out
		'';
		dontPatchELF = true;
	};
	wrapperScripts = import Dist/wrapper-scripts.nix {
		inherit (pkgs) lib writeShellScriptBin writeText;
		inherit commentUnless versionAtLeast bizhawk mesa openal debugPInvokes initConfig;
		hawkVersion = hawkSourceInfo.version;
		mono = monoFinal;
	};
	mkWrapperWrapper = { pname, innerWrapper, desktopName }: stdenv.mkDerivation rec {
		inherit pname;
		version = hawkSourceInfo.version;
		exeName = "${pname}-${version}";
		nativeBuildInputs = [ makeWrapper ];
		buildInputs = [ bizhawk ];
		# there must be a helper for this somewhere...
		dontUnpack = true;
		dontPatch = true;
		dontConfigure = true;
		dontBuild = true;
		installPhase = ''
			mkdir -p $out/bin
			makeWrapper ${innerWrapper} $out/bin/${exeName} \
				--set BIZHAWK_HOME ${bizhawk}
		'';
		dontFixup = true;
#		desktopItems = [ (makeDesktopItem {
#			name = "${pname}-${version}"; # actually filename
#			exec = "${exeName}";
#			inherit desktopName; # actually Name
#		}) ];
	};
in {
	bizhawkAssemblies = bizhawk; # assemblies and dependencies, and some other immutable things like the gamedb, are in the `bin` output; the rest of the "assets" (bundled scripts, palettes, etc.) are in the `out` output
	discohawk = mkWrapperWrapper {
		pname = "discohawk-monort";
		innerWrapper = "${wrapperScripts.discoWrapper}/bin/discohawk-wrapper";
		desktopName = "DiscoHawk (Mono Runtime)";
	};
	emuhawk = mkWrapperWrapper {
		pname = "emuhawk-monort";
		innerWrapper = if forNixOS
			then "${wrapperScripts.wrapperScript}/bin/emuhawk-wrapper"
			else "${wrapperScripts.wrapperScriptNonNixOS}/bin/emuhawk-wrapper-non-nixos";
		desktopName = "EmuHawk (Mono Runtime)";
	};
	emuhawkWrapperScriptNonNixOS = wrapperScripts.wrapperScriptNonNixOS;
	mono = monoFinal;
}
