module RpmSpecHelpers
  def rpm_macros
    <<EOF
# BEGIN shared macros for all dependency packages
%if 0%{?is_opensuse}
%define stack opensuse42
%else
%define stack sle12
%endif

%define otherdir %{_topdir}/OTHER
%define prefix_path /app/vendor/%{name}
%define destdir /tmp/%{name}/%{prefix_path}
# END shared macros
EOF
  end
end
