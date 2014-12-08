{% from 'gatling/settings.sls' import gatling with context %}
{% set web_interface = salt['pillar.get']('interfaces:public', 'eth0') %}
{% set webs = salt['publish.publish']('roles:magento_web', 'network.ip_addrs', web_interface, 'grain').values() %}
{% set simulation_tar = "gatling.simulations.magento.tar.gz" %}

include:
  - gatling

curl:
  pkg.installed

/opt/{{ gatling.dir }}/user-files/data/buyers.csv:
  file.managed:
    - source: salt://magento/files/gatling-buyers.csv

/opt/{{ gatling.dir }}/user-files/simulations/{{ simulation_tar }}:
  file.managed:
    - source: salt://magento/files/{{ simulation_tar }}

tar -zxf {{ simulation_tar }}:
  cmd.watch:
    - cwd: /opt/{{ gatling.dir }}/user-files/simulations/
    - watch:
      - file: /opt/{{ gatling.dir }}/user-files/simulations/{{ simulation_tar }}

{% for web in webs %}
curl -L http://{{ web[0] }}/magento >> /root/curlresults:
  cmd.run:
    - require:
      - pkg: curl

sleep for {{ web }}: 
  cmd.watch:
    - name: sleep 30
    - watch:
      - cmd: curl -L http://{{ web[0] }}/magento >> /root/curlresults

{% endfor %}
