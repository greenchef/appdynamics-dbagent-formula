{%- from 'appdynamics-dbagent/conf/settings.sls' import appd with context %}

### APPLICATION INSTALL ###
unpack-appdynamics-dbagent-tarball:
  archive.extracted:
    - name: {{ appd.prefix }}/dbagent-{{ appd.version }}
    - source: {{ appd.source_url }}/dbagent-{{ appd.version }}.zip
    - source_hash: {{ salt['pillar.get']('appdynamics-dbagent:source_hash', '') }}
    - archive_format: zip
    - user: {{ appd.user }}
    - keep: True
    - require:
      - module: appdynamics-dbagent-stop
      - file: appdynamics-dbagent-init-script
      - user: {{ appd.user }}
    - listen_in:
      - module: appdynamics-dbagent-restart

fix-appdynamics-dbagent-filesystem-permissions:
  file.directory:
    - user: {{ appd.user }}
    - recurse:
      - user
    - names:
      - {{ appd.prefix }}/dbagent-{{ appd.version }}
      - {{ appd.home }}
    - watch:
      - archive: unpack-appdynamics-dbagent-tarball

create-appdynamics-dbagent-symlink:
  file.symlink:
    - name: {{ appd.prefix }}/appdynamics-dbagent
    - target: {{ appd.prefix }}/dbagent-{{ appd.version }}
    - user: {{ appd.user }}
    - watch:
      - archive: unpack-appdynamics-dbagent-tarball

### SERVICE ###
appdynamics-dbagent-service:
  service.running:
    - name: appdynamics-dbagent
    - enable: True
    - require:
      - archive: unpack-appdynamics-dbagent-tarball
      - file: appdynamics-dbagent-init-script

# used to trigger restarts by other states
appdynamics-dbagent-restart:
  module.wait:
    - name: service.restart
    - m_name: appdynamics-dbagent

appdynamics-dbagent-stop:
  module.wait:
    - name: service.stop
    - m_name: appdynamics-dbagent

appdynamics-dbagent-init-script:
  file.managed:
    - name: '/lib/systemd/system/appdynamics-dbagent.service'
    - source: salt://appdynamics-dbagent/templates/appdynamics-dbagent.service.tmpl
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
    - context:
      appd: {{ appd|json }}

create-appdynamics-dbagent-service-symlink:
  file.symlink:
    - name: '/etc/systemd/system/appdynamics-dbagent.service'
    - target: '/lib/systemd/system/appdynamics-dbagent.service'
    - user: root
    - watch:
      - file: appdynamics-dbagent-init-script

ensure-user-present:
  user.present
    - name: {{ appd.user }}

### FILES ###
{{ appd.prefix }}/appdynamics-dbagent/conf/controller-info.xml:
  file.managed:
    - source: salt://appdynamics-dbagent/templates/controller-info.xml.tmpl
    - user: {{ appd.user }}
    - template: jinja
    - listen_in:
      - module: appdynamics-restart
