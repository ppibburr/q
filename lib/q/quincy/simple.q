require "Q/uincy"

macro :escape_html, 'GLib.Markup.escape_text(%v1___escape_html)'
macro :'get', 'Quincy.init().get(%v1___get, '
macro :'post', 'Quincy.init().post(%v1___post, '
macro :'getx', 'Quincy.init().getx(%v1___getx, '
macro :'postx', 'Quincy.init().postx(%v1___postx, '
macro :'port','Quincy.init().port = %v1___port;'
macro :'base_dir','Quincy.init().base_dir = %v1___base_dir;
Quincy.init().getx("/(.*)", (match) => {
  return match.render_file(match.match_data[0]);
});'
macro :param, 'match.param(%v1___param)'
macro :add_mimetype, 'Quincy.MimeTypeQuery.add_type(%v1___add_mimetype, %v2___add_mimetype);'

namespace module Quincy
  Q.at_exit "
    Quincy.init().run();
  "
end
