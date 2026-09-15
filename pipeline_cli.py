"""Selección explícita de proyectos antes de cualquier acceso a Zoho o BigQuery."""
import argparse


class ProjectParser(argparse.ArgumentParser):
    def error(self, message):
        self.print_usage()
        self.exit(1, f"{self.prog}: {message}\n")


def select_projects(projects, allow_all=False, argv=None):
    parser = ProjectParser(description="Seleccionar explícitamente el proyecto del pipeline")
    parser.add_argument('project', nargs='?', choices=list(projects), help='Proyecto a procesar')
    if allow_all:
        parser.add_argument('--all', action='store_true', help='Procesar todos los proyectos configurados')
    args = parser.parse_args(argv)
    all_projects = getattr(args, 'all', False)
    if all_projects and args.project:
        parser.error('Usá un proyecto o --all, no ambos')
    if all_projects:
        return list(projects)
    if not args.project:
        parser.error('Debés indicar un proyecto' + (' o --all' if allow_all else ''))
    return [args.project]
