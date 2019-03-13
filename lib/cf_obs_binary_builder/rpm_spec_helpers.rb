module RpmSpecHelpers
  def rpm_macros
    <<EOF
# BEGIN shared macros for all dependency packages
BuildRequires: aaa_stack_build_requires

%if 0%{?suse_version} == 1315
%define stack sle12
%else
%define stack sle15
%endif

%define otherdir %{_topdir}/OTHER
%define prefix_path /app/vendor/%{name}
%define destdir /tmp/%{name}
%define dependencydir %{destdir}%{prefix_path}
# END shared macros
EOF
  end
end
