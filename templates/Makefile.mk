{{ $distro := (ds "distro") -}}
{{ $pipelines := ($distro.pipelines | coll.Sort "order") -}}
{{ $lastPipeline := (index $pipelines (math.Sub (len $pipelines) 1)) -}}
COMPOSE=docker compose -f {{ $distro.dirs.spec }}/compose.yml
QEMU=qemu-system-x86_64 -smp 2 -m 512 -vnc :0 \
	-net nic,vlan=0,macaddr=52:54:00:12:34:22,model=e1000,addr=08 \
	-net tap,ifname=tap-qemu,script=no,downscript=no

exec:
	@cd {{ $distro.dirs.disks }}; qemu-img create -f qcow2 -b pipeline.{{ $lastPipeline.name }}.qcow2 exec.qcow2
	$(QEMU) -hda {{ $distro.dirs.disks }}/exec.qcow2

exec%:
	$(eval DISTRO_NAME:=$(firstword $(subst :, ,$*)))
	$(eval PIPELINE_NAME:=$(subst :, ,$*))
	@cd {{ $distro.dirs.disks }}; qemu-img create -f qcow2 -b pipeline.$(PIPELINE_NAME).qcow2 exec.$(PIPELINE_NAME).qcow2
	$(QEMU) -hda {{ $distro.dirs.disks }}/exec.$(PIPELINE_NAME).qcow2

builder:
	@docker build --build-arg DISTRO_VER={{ $distro.environment.DISTRO_VER}} -t {{ $distro.builder }} -f distro/{{ $distro.name }}/Dockerfile .

builder-push:
	@docker push {{ $distro.builder }}

builder-pull:
	@docker pull {{ $distro.builder }}

#===============================================================================
# Pipelines
build: {{ range $pipelines }} build-{{ .name }}{{ end }}
{{- range $pn, $pipeline := $pipelines }}
{{- $items := $pipeline.items | coll.Sort }}
build-{{ $pipeline.name }}: pipeline-{{ $pipeline.name }}{{ range $items }} job-{{ $pipeline.name }}-{{ .}}{{ end }}
job-{{ $pipeline.name }}-%:
	@$(COMPOSE) run --rm {{ $pipeline.name }}-$*
{{- end }}
pipeline-%:
	@$(COMPOSE) run --rm pipeline-$*


#===============================================================================
# Editions
editions:{{ range $distro.editions }} edition@{{ .name }}{{ end }}
{{- range $n, $edition := $distro.editions }}
job@{{ $edition.name }}:
	@$(COMPOSE) run --rm edition-{{ $edition.name }}
{{- $items := $edition.items | coll.Sort }}
job@{{ $edition.name }}-%:
	@$(COMPOSE) run --rm edition-{{ $edition.name }}-$*
edition@{{ $edition.name }}: job@{{ $edition.name }}{{ range $items }} job@{{ $edition.name }}-{{ . }}{{ end }}
{{- end }}


#===============================================================================
# artifacts
artifacts: artifact-vmdk artifact-ova

artifact-vmdk:
	@$(COMPOSE) run --rm artifact-vmdk

artifact-ova:
	@$(COMPOSE) run --rm artifact-ova

artifacts-upload:
	@$(COMPOSE) run --rm artifact-ova-upload

{{ range $distro.editions }}
artifacts@{{ .name }}: artifact-vmdk@{{ .name }} artifact-ova@{{ .name }}

artifact-vmdk@{{ .name }}:
	@$(COMPOSE) run --rm artifact-vmdk.{{ .name }}

artifact-ova@{{ .name }}:
	@$(COMPOSE) run --rm artifact-ova.{{ .name }}
{{- end }}
