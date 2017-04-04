require './train'
require 'test/unit'
class TestSch_2level < Test::Unit::TestCase
    def setup
        # 1.setup sch_node object
        @sch_level = []
        @sch_level << @fq = (Sch.new('fq_0')..Sch.new('fq_7')).to_a
        @sch_level << @sqp = (Sch.new('sqp_0')..Sch.new('sqp_3')).to_a
        @sch_level << @root = [Sch.new('root_0')]
        # 2.cfg sch_tree/shaper/sch_type/fq's enq
        @fq.each do |node|
            node.plug(@sqp.index_id(0))
            node.enq = 125000
        end
        @sqp.each do |node|
            node.plug(@root.index_id(0))
        end
    end
    def test_wrr_simple

        @sqp[0].cir = 450000
        @sqp[0].eir = 0
        @sqp[0].sch_type = 'wrr'
        # 3.update enq from bottom to top,by level
        @sch_level.each do |level|
            level.each do |node|
                node.cal_enq.upload_enq
            end
        end

        # 4.update deq from top to bottom,by prior/level
        @sch_level.reverse.each do |level|
            level.each do |node|
                node.update_deq
            end
        end
        fq_deq_expect = [56250, 56250, 56250, 56250, 56250, 56250, 56250, 56250]
        fqid = 0
        @root[0].print_tree
        fq_deq_expect.each do |deq_expect|
            assert_equal(fq_deq_expect[fqid], @fq[fqid].deq)
        end
    end
    def test_sp_simple
        @sqp[0].cir = 450000
        @sqp[0].eir = 0
        @sqp[0].sch_type = 'sp'
        # 3.update enq from bottom to top,by level
        @sch_level.each do |level|
            level.each do |node|
                node.cal_enq.upload_enq
            end
        end

        # 4.update deq from top to bottom,by prior/level
        @sch_level.reverse.each do |level|
            level.each do |node|
                node.update_deq
            end
        end
        fq_deq_expect = [125000, 125000, 125000, 75000, 0, 0, 0, 0]
        fqid = 0
        fq_deq_expect.each do |deq_expect|
            assert_equal(fq_deq_expect[fqid], @fq[fqid].deq)
        end
    end
    def test_wrr_1

        @sqp[0].cir = 70000
        @sqp[0].eir = 70000
        @sqp[0].sch_type = 'wrr'
        fq_weight = [50, 10, 10, 5, 5, 5, 5, 10]
        fq_enq = [50000, 100000, 75000, 50000, 50000, 50000, 50000, 50000]
        fq_deq_expect = [50000, 18000, 18000, 9000, 9000, 9000, 9000, 18000]
        fqid = 0
        @fq.each do |node|
            node.enq = fq_enq[fqid]
            node.weight = fq_weight[fqid]
            fqid += 1
        end
        # 3.update enq from bottom to top,by level
        @sch_level.each do |level|
            level.each do |node|
                node.cal_enq.upload_enq
            end
        end

        # 4.update deq from top to bottom,by prior/level
        @sch_level.reverse.each do |level|
            level.each do |node|
                node.update_deq
            end
        end
        fqid = 0
        @root[0].print_tree
        fq_deq_expect.each do |deq_expect|
            assert_equal(fq_deq_expect[fqid], @fq[fqid].deq)
        end
    end
end
