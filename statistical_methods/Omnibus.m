classdef Omnibus
    properties (Constant)
        level = "whole_brain";
        permutation_based = true;
        % Add remaning methods here when implemented
        submethod = {'Multidimensional_cNBS'};
    end
    
    methods

        function pval = run_method(~,varargin)
            % Computes Omnibus test statistics using different submethods.
            %
            % Inputs:
            %   - STATS: Structure containing statistical parameters.
            %   - edge_stats: Raw test statistics for edges.
            %   - permuted_edge_data: Precomputed permutation edge statistics.
            %   - omnibus_type: String specifying the Omnibus submethod.
            %
            % Outputs:
            %   - pval: P-values computed using the selected Omnibus method.
        
            params = struct(varargin{:});
        
            % Extract relevant inputs
            STATS = params.statistical_parameters;
            network_stats = params.network_stats;
            permuted_network_stats = params.permuted_network_data;
            
            pval = struct();

            % Select appropriate Omnibus method
            if STATS.submethods.Multidimensional_cNBS
                pval.Multidimensional_cNBS = Multidimensional_cNBS(network_stats, permuted_network_stats);
            end
             
            % This comment is here to save submethods names - the only
            % implemented is the Multidimensional_cNBS 
            %switch STATS.omnibus_type
            %    case 'Multidimensional_cNBS'
            %        pval = Multidimensional_cNBS(network_stats, permuted_network_stats);
            %    case 'Threshold_Positive'
            %        pval = Threshold_Omnibus(STATS, edge_stats, permuted_edge_stats, 'positive');
            %    case 'Threshold_Both_Dir'
            %        pval = Threshold_Omnibus(STATS, edge_stats, permuted_edge_stats, 'both');
            %    case 'Average_Positive'
            %        pval = Average_Omnibus(STATS, edge_stats, permuted_edge_stats, 'positive');
            %    case 'Average_Both_Dir'
            %        pval = Average_Omnibus(STATS, edge_stats, permuted_edge_stats, 'both');
            %    case 'Multidimensional_all_edges'
            %        pval = Multidimensional_all_edges(STATS, edge_stats, permuted_edge_stats);
            %    otherwise
            %        error('Omnibus type "%s" not recognized.', omnibus_type);
            %end
        end

    end

end