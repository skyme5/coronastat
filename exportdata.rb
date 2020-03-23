#!/usr/bin/env ruby
# frozen_string_literal: false

require 'csv'
require 'json'

require 'chroma'

INDIAN_STATES = {
  AN: 'Andaman & Nicobar Island',
  AP: 'Andhra Pradesh',
  AR: 'Arunanchal Pradesh',
  AS: 'Assam',
  BR: 'Bihar',
  CH: 'Chandigarh',
  CT: 'Chhattisgarh',
  DD: 'Daman & Diu',
  DL: 'Delhi',
  DN: 'Dadara & Nagar Havelli',
  GA: 'Goa',
  GJ: 'Gujarat',
  HP: 'Himachal Pradesh',
  HR: 'Haryana',
  JH: 'Jharkhand',
  JK: 'Jammu and Kashmir',
  KA: 'Karnataka',
  KL: 'Kerala',
  LD: 'Lakshadweep',
  MH: 'Maharashtra',
  ML: 'Meghalaya',
  MN: 'Manipur',
  MP: 'Madhya Pradesh',
  MZ: 'Mizoram',
  NL: 'Nagaland',
  OD: 'Odisha',
  PB: 'Punjab',
  PY: 'Puducherry',
  RJ: 'Rajasthan',
  SK: 'Sikkim',
  TN: 'Tamil Nadu',
  TR: 'Tripura',
  TS: 'Telengana',
  UK: 'Uttarakhand',
  UP: 'Uttar Pradesh',
  WB: 'West Bengal',
  LK: 'Ladakh'
}

def heatmap_color_for(value, type)
  n = (255.0 * value).floor
  if type == 'death'
    r = 255 - n
    g = 255 - n
    b = 255 - n
  elsif type == 'cured'
    r = 255 - n
    g = 255
    b = 255 - n
  else
    r = 255
    g = 255 - n
    b = 255 - n
  end

  color = ['rgb(', r, ',', g, ',', b, ')'].join('')
  Chroma.paint(color).to_hex
end

data = CSV.read('corona.cases.csv', col_sep: "\t", converters: %i[numeric])

total = 0
foreign = 0
cured = 0
death = 0
data.each do |e|
  total = e[2] if total < e[2]
  foreign = e[3] if foreign < e[3]
  cured = e[4] if cured < e[4]
  death = e[5] if death < e[5]
end

json = []
colormap = {
  'total' => { "fills": { defaultFill: 'white' }, "states": {} },
  'cured' => { "fills": { defaultFill: 'white' }, "states": {} },
  'death' => { "fills": { defaultFill: 'white' }, "states": {} }
}

MAX = { 'total' => total, 'cured' => cured, 'death' => death }

data.each do |e|
  [['total', 2], ['cured', 4], ['death', 5]].each do |type|
    color = heatmap_color_for(1.0 * e[type.last] / MAX[type.first], type.first)
    colormap[type.first][:states][INDIAN_STATES.key(e[1])] = {
      fillKey: color,
      info: [
        e[2],
        (100.0 * e[2] / total).round(2),
        e[3],
        (100.0 * e[3] / foreign).round(2),
        e[4],
        (100.0 * e[4] / cured).round(2),
        e[5],
        (100.0 * e[5] / death.round(2))
      ]
    }
    colormap[type.first][:fills][color] = color
  end

  json <<
    {
      centered: INDIAN_STATES.key(e[1]),
      radius: 1.0 + (30 * e[2] / total).round(2),
      state: e[1],
      info: [
        e[2],
        (100.0 * e[2] / total).round(2),
        e[3],
        (100.0 * e[3] / foreign).round(2),
        e[4],
        (100.0 * e[4] / cured).round(2),
        e[5],
        (100.0 * e[5] / death.round(2))
      ]
    }
end

out = File.open('corona_status.json', 'w')
out.puts JSON.generate(json)
out.close

out = File.open('corona_status.color.json', 'w')
out.puts JSON.generate(colormap)
out.close
